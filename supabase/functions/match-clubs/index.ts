// Supabase Edge Function: match-clubs
// Runs SERVER-SIDE on Supabase. Holds the Groq key as a secret (never in the frontend).
//
// This function does NOT rank or score clubs. Ranking and match percentages are
// computed locally in the frontend from the clubs' score vectors, so that the
// same answers always produce the same order and the same numbers. Letting the
// model rank made results shuffle between runs (a club could sit at #4 with 82%
// and then #1 with 92% on an identical re-submit) and cost ~7.3k tokens a call,
// which blew through the free tier's 8k tokens/minute after a single quiz.
//
// All this function does is write one short "why this fits" sentence for each
// club on a shortlist the frontend already decided on. The request carries only
// those few clubs (name + description) instead of the whole catalogue with score
// vectors, so a call costs roughly a tenth as much and many more students can
// submit inside the same per-minute budget.
//
// Provider note: Gemini (gemini-2.5-flash) was evaluated as a replacement and
// returned clean schema-valid JSON at comparable latency, but its free tier caps
// at 20 requests per day per model — fewer than Groq's 200k tokens/day buys
// here, and unlike Groq's token-based cap it does not benefit from the
// shortlist optimization below. Staying on Groq until there is a paid tier.
//
// Secrets this function expects (set via `supabase secrets set`, NOT in code):
//   GROQ_API_KEY  - your gsk_... key

const GROQ_MODEL = "openai/gpt-oss-20b";
const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";

// Strict output contract. With plain `json_object` the model intermittently
// produced output Groq rejected ("Failed to validate JSON"), reproducibly for
// some inputs. A json_schema constrains decoding to this exact shape.
const RESULT_SCHEMA = {
  type: "object",
  properties: {
    results: {
      type: "array",
      items: {
        type: "object",
        properties: {
          id: { type: "string" },
          reason: { type: "string" },
        },
        required: ["id", "reason"],
        additionalProperties: false,
      },
    },
  },
  required: ["results"],
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
    // actually does and the rest is detail that does not change the sentence
    // the model writes.
    const firstSentence = (d: string) => {
      const m = /^.*?[.!?](?=\s|$)/.exec(d ?? "");
      return (m ? m[0] : (d ?? "")).trim();
    };

    // The shortlist comes from the caller. Cap it and trim the fields so a
    // malformed or oversized request can't inflate the token cost.
    const shortlist = (Array.isArray(clubs) ? clubs : [])
      .slice(0, 8)
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

    const system = [
      "You write one-sentence explanations for a high-school club recommender.",
      "You are given a student's quiz answers and a shortlist of clubs that have ALREADY been matched to them.",
      "Do not rank, reorder, score, add, or remove clubs. Return exactly one entry for every club given, in the same order.",
      "For each club write ONE short sentence (max 18 words) saying why it fits THIS student, referring to their specific interests or career goals.",
      "Write plainly, address the student's own words where possible, and never mention percentages or rankings.",
      'Return STRICT JSON only: {"results":[{"id":"club-id","reason":"one short sentence"}]}. Copy each "id" verbatim from the shortlist.',
    ].join(" ");

    const user = JSON.stringify({ student, clubs: shortlist });

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
        // reasoning and guarantee room for the answer. The answer is now just a
        // handful of short sentences, so this budget is much smaller than the
        // old ranking call needed.
        reasoning_effort: "low",
        max_completion_tokens: 800,
        response_format: {
          type: "json_schema",
          json_schema: { name: "club_reasons", strict: true, schema: RESULT_SCHEMA },
        },
        messages: [
          { role: "system", content: system },
          { role: "user", content: user },
        ],
      }),
    });

    if (!groqRes.ok) {
      const detail = await groqRes.text();
      // Signal failure clearly. The frontend already has its ranking and
      // percentages, so it simply shows matched-interest labels instead.
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

    // Only hand back reasons for ids that were actually on the shortlist.
    const allowed = new Set(shortlist.map((c) => c.id));
    const results = (Array.isArray(parsed?.results) ? parsed.results : [])
      .filter((r: { id?: string; reason?: string }) => r?.id && allowed.has(r.id) && r?.reason)
      .map((r: { id: string; reason: string }) => ({ id: r.id, reason: String(r.reason).slice(0, 200) }));

    return new Response(
      JSON.stringify({ ok: true, results, usage: groqJson?.usage ?? null }),
      { headers: { ...cors, "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ ok: false, error: String(e) }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } },
    );
  }
});
