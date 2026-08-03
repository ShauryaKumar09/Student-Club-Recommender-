// Supabase Edge Function: match-clubs
// Runs SERVER-SIDE on Supabase. Holds the Groq key as a secret (never in the frontend).
//
// This function RANKS a shortlist of clubs for one student and writes a short
// "why this fits" sentence for the five it puts on top.
//
// Ranking used to live entirely in the frontend, as cosine similarity over a
// 19-dimension score vector, and this function was forbidden from reordering
// anything. That was cheap but wrong in ways the scoring could not be tuned out
// of: a student who typed "I want to be a dancer" got Dance Club at #6, behind
// Art Club, Band, Choirs and Orchestras, because the stemmer never connects
// "dancer" to "Dance" and because every arts club shares one broad dimension
// while Dance Club's extra dimensions inflate its vector norm, so cosine
// actively penalises the right answer. A model reading the student's sentence
// next to "Dance Club: choreography and performance" does not make that mistake.
//
// Local scoring still picks WHICH clubs are worth asking about (8 of them, or 10
// when the student typed something), so the request stays small. It no longer
// decides the order.
//
// Token discipline: clubs go over the wire NUMBERED and the model answers in
// numbers. A club id like "creative-writing-club" costs several tokens every
// time it appears, and it appeared twice per club in the old contract. Even
// with the ranking added, a call costs about a third less than the old
// explain-only one.
//
// Secrets this function expects (set via `supabase secrets set`, NOT in code):
//   GROQ_API_KEY  - your gsk_... key

const GROQ_MODEL = "openai/gpt-oss-20b";
const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";

// Strict output contract. With plain `json_object` the model intermittently
// produced output Groq rejected ("Failed to validate JSON"), reproducibly for
// some inputs. A json_schema constrains decoding to this exact shape.
//
// The ranking IS the `top` list: the model names its five best clubs in order
// and justifies each, then lists whatever is left in `rest`. An earlier shape
// asked for a separate full `order` array alongside the reasons, and the model
// reliably filled that array with 1,2,3... unchanged while putting its real
// opinion in the reasons -- it would explain why Dance Club was the obvious
// answer and rank it sixth in the same breath. Deriving the order from the list
// it demonstrably gets right removes that failure, and each number now appears
// once instead of twice.
const RESULT_SCHEMA = {
  type: "object",
  properties: {
    top: {
      type: "array",
      items: {
        type: "object",
        properties: {
          n: { type: "integer" },
          why: { type: "string" },
        },
        required: ["n", "why"],
        additionalProperties: false,
      },
    },
    rest: {
      type: "array",
      items: { type: "integer" },
    },
  },
  required: ["top", "rest"],
  additionalProperties: false,
};

// CORS: allow the browser to call this function.
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Compact the student's style answers into a few words the model can use
// without spending tokens on the raw 1-5 scale.
const STYLE_WORDS: Record<string, string[]> = {
  competitiveness: ["just for fun", "mostly casual", "a mix of fun and competition", "fairly competitive", "highly competitive"],
  time_commitment: ["very little time", "occasional", "a regular weekly commitment", "a big time commitment", "an all-in commitment"],
  team_vs_individual: ["working alone", "mostly alone", "a mix of solo and group", "mostly team-based", "strongly team-based"],
  public_speaking_emphasis: ["no public speaking", "little public speaking", "some public speaking", "frequent speaking", "lots of speaking"],
  leadership_opportunity: ["no leadership role", "maybe a small role", "some responsibility", "a leadership role", "strong leadership opportunities"],
};

function describeStyle(answers: Record<string, number>): string[] {
  return Object.entries(answers ?? {})
    .filter(([k, v]) => STYLE_WORDS[k] && typeof v === "number" && v >= 1 && v <= 5)
    .map(([k, v]) => STYLE_WORDS[k][v - 1]);
}

Deno.serve(async (req) => {
  // Browser preflight
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const groqKey = Deno.env.get("GROQ_API_KEY");
    if (!groqKey) throw new Error("GROQ_API_KEY not set");

    const body = await req.json();
    const {
      interests = [],
      careerGoals = [],
      styleAnswers = {},
      customText = "",
      clubs = [],
    } = body ?? {};

    // Descriptions run 1-3 sentences; the opening one says what the club
    // actually does and the rest is detail that does not change the ranking.
    const firstSentence = (d: string) => {
      const m = /^.*?[.!?](?=\s|$)/.exec(d ?? "");
      return (m ? m[0] : (d ?? "")).trim();
    };

    // The candidates come from the caller. Cap the list and trim the fields so a
    // malformed or oversized request can't inflate the token cost.
    const shortlist = (Array.isArray(clubs) ? clubs : [])
      .slice(0, 10)
      .map((c: { id?: string; name?: string; description?: string }) => ({
        id: String(c?.id ?? "").slice(0, 60),
        name: String(c?.name ?? "").slice(0, 80),
        description: firstSentence(String(c?.description ?? "")).slice(0, 200),
      }))
      .filter((c) => c.id && c.name);

    if (!shortlist.length) {
      return new Response(JSON.stringify({ ok: false, error: "no clubs supplied" }), {
        status: 400,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const student = [
      interests.length ? `Interests: ${interests.slice(0, 18).join(", ")}.` : "",
      careerGoals.length ? `Career fields they want to explore: ${careerGoals.slice(0, 14).join(", ")}.` : "",
      describeStyle(styleAnswers).length ? `Prefers: ${describeStyle(styleAnswers).join(", ")}.` : "",
      customText ? `In their own words: ${String(customText).slice(0, 300)}.` : "",
    ].filter(Boolean).join(" ");

    // Numbered 1..N. The model only ever handles these numbers.
    const numbered = shortlist
      .map((c, i) => `${i + 1} ${c.name}: ${c.description}`)
      .join("\n");

    const system = [
      "Rank high-school clubs for a student. You get their answers and a numbered club list.",
      'Return JSON only: {"top":[{"n":club number,"why":"one sentence, max 18 words"}],"rest":[club numbers]}.',
      `"top" holds the ${Math.min(5, shortlist.length)} clubs that fit this student best, the single best one FIRST.`,
      '"rest" holds every other number, still best first.',
      "The order you put them in is the recommendation, so put the club that most directly does what the student asked for at the top, even if it is far down the list you were given.",
      "Their own typed words outrank the checkboxes.",
      "Each number appears exactly once across both lists. Use only the numbers given; never invent one.",
      "Never mention percentages or rankings in a reason.",
    ].join(" ");

    const user = `Student: ${student}\n\nClubs:\n${numbered}`;

    const groqRes = await fetch(GROQ_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${groqKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        temperature: 0.2,
        // gpt-oss-20b is a reasoning model. Left unbounded its reasoning can eat
        // the whole completion budget and return an empty body, which Groq then
        // rejects as json_validate_failed with failed_generation:"". Cap the
        // reasoning and guarantee room for the answer.
        reasoning_effort: "low",
        max_completion_tokens: 800,
        response_format: {
          type: "json_schema",
          json_schema: { name: "club_ranking", strict: true, schema: RESULT_SCHEMA },
        },
        messages: [
          { role: "system", content: system },
          { role: "user", content: user },
        ],
      }),
    });

    if (!groqRes.ok) {
      const detail = await groqRes.text();
      // Signal failure clearly. The frontend falls back to its own local order.
      return new Response(
        JSON.stringify({ ok: false, error: `Groq ${groqRes.status}`, detail }),
        { status: 502, headers: { ...cors, "Content-Type": "application/json" } },
      );
    }

    const groqJson = await groqRes.json();
    const content = groqJson?.choices?.[0]?.message?.content ?? "{}";
    let parsed;
    try {
      parsed = JSON.parse(content);
    } catch {
      return new Response(
        JSON.stringify({ ok: false, error: "bad JSON from model", raw: content }),
        { status: 502, headers: { ...cors, "Content-Type": "application/json" } },
      );
    }

    // Repair the ranking rather than trusting it. A model that repeats a number,
    // invents one, or stops early would otherwise drop clubs off the student's
    // results entirely -- a worse outcome than the local order this replaced.
    // Anything invalid is discarded and anything missing is appended in the
    // order it was sent, so the output is always a full permutation of 1..N.
    const seen = new Set<number>();
    const rankedIdx: number[] = [];
    const take = (raw: unknown) => {
      const n = Math.trunc(Number(raw));
      if (!Number.isFinite(n) || n < 1 || n > shortlist.length || seen.has(n)) return false;
      seen.add(n);
      rankedIdx.push(n);
      return true;
    };

    const results: { id: string; reason: string }[] = [];
    for (const r of Array.isArray(parsed?.top) ? parsed.top : []) {
      if (!take(r?.n)) continue;
      const id = shortlist[Math.trunc(Number(r.n)) - 1].id;
      if (r?.why) results.push({ id, reason: String(r.why).slice(0, 200) });
    }
    for (const raw of Array.isArray(parsed?.rest) ? parsed.rest : []) take(raw);
    for (let n = 1; n <= shortlist.length; n++) {
      if (!seen.has(n)) rankedIdx.push(n);
    }

    const order = rankedIdx.map((n) => shortlist[n - 1].id);

    return new Response(
      JSON.stringify({ ok: true, order, results, usage: groqJson?.usage ?? null }),
      { headers: { ...cors, "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ ok: false, error: String(e) }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } },
    );
  }
});
