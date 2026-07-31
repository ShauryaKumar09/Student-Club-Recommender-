// Supabase Edge Function: match-clubs
// Runs SERVER-SIDE on Supabase. Holds the Groq key as a secret (never in the frontend).
//
// Flow:
//   frontend sends the user's quiz answers  ->  this function
//   this function reads all clubs (incl. scores) from the DB
//   -> asks Groq to rank them, grounded in the club data
//   -> returns a ranked list to the frontend
//
// The frontend keeps its own local scoring as a fallback for when THIS call fails.
//
// Secrets this function expects (set via `supabase secrets set`, NOT in code):
//   GROQ_API_KEY            - your gsk_... key
//   SUPABASE_URL            - auto-provided by Supabase
//   SUPABASE_ANON_KEY       - auto-provided by Supabase

import { createClient } from "jsr:@supabase/supabase-js@2";

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
          matchPercent: { type: "number" },
          reason: { type: "string" },
        },
        required: ["id", "matchPercent", "reason"],
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

Deno.serve(async (req) => {
  // Browser preflight
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const groqKey = Deno.env.get("GROQ_API_KEY");
    if (!groqKey) throw new Error("GROQ_API_KEY not set");

    // What the frontend sends us: the user's selections + free text.
    const body = await req.json();
    const { interests = [], styleAnswers = {}, customText = "", limit = 8 } = body ?? {};

    // Pull the clubs (with scores) from the DB, server-side.
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
    );
    const { data: clubs, error } = await supabase
      .from("clubs")
      .select("id, name, category, description, interests, scores");
    if (error) throw error;

    // Build a compact catalog for the model. We include the 19-dimension
    // scores so the model ranks against real data about each club, not guesses.
    // The score KEYS are sent once in the system prompt and each club's scores
    // as a bare array in that order — repeating 19 long key names per club for
    // 38 clubs blew past Groq's 8k tokens/min limit (8109 requested). Same data,
    // ~4700 tokens -> ~400.
    const scoreKeys = Object.keys((clubs ?? [])[0]?.scores ?? {});
    const catalog = (clubs ?? []).map((c) => ({
      id: c.id,
      name: c.name,
      category: c.category,
      description: c.description,
      interests: c.interests,
      s: scoreKeys.map((k) => c.scores?.[k] ?? 0),
    }));

    const system = [
      "You are a high-school club recommender.",
      "You are given a catalog of clubs, each with a description and an 's' array rating it 0-5 on 19 dimensions (subject interests plus style dimensions like competitiveness, time_commitment, team_vs_individual, public_speaking_emphasis, leadership_opportunity).",
      `The values in each club's 's' array correspond, in order, to these dimensions: ${JSON.stringify(scoreKeys)}.`,
      "You are also given a student's quiz answers and a free-text description of their interests.",
      "Rank the clubs by genuine fit for THIS student. Use the scores as ground truth about what each club is actually like; use the free text to understand the student in ways the checkboxes can't capture.",
      `Return STRICT JSON only, no prose: {"results":[{"id":"club-id","matchPercent":0-100,"reason":"one short sentence"}]}. Return at most ${limit} clubs, best first. Only include clubs that are a real fit.`,
      'Every object must have all three fields. "id" must be copied verbatim from the catalog. "matchPercent" must be a plain integer with no % sign. "reason" must be a single sentence with no line breaks.',
      'Example of a valid response: {"results":[{"id":"robotics","matchPercent":92,"reason":"Hands-on building and coding with a competitive season."},{"id":"chess-club","matchPercent":64,"reason":"Strategic problem solving in a low-pressure setting."}]}',
    ].join(" ");

    const user = JSON.stringify({
      student: { interests, styleAnswers, customText },
      clubs: catalog,
    });

    const groqRes = await fetch(GROQ_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${groqKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        temperature: 0.3,
        // gpt-oss-20b is a reasoning model. Left unbounded its reasoning can eat
        // the whole completion budget and return an empty body, which Groq then
        // rejects as json_validate_failed with failed_generation:"". Cap the
        // reasoning and guarantee room for the answer.
        reasoning_effort: "low",
        max_completion_tokens: 2048,
        response_format: {
          type: "json_schema",
          json_schema: { name: "club_matches", strict: true, schema: RESULT_SCHEMA },
        },
        messages: [
          { role: "system", content: system },
          { role: "user", content: user },
        ],
      }),
    });

    if (!groqRes.ok) {
      const detail = await groqRes.text();
      // Signal failure clearly so the frontend falls back to local scoring.
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

    return new Response(
      JSON.stringify({ ok: true, results: parsed.results ?? [] }),
      { headers: { ...cors, "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ ok: false, error: String(e) }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } },
    );
  }
});
