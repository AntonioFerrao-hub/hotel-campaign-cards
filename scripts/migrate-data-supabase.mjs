import { createClient } from "@supabase/supabase-js";

const SRC_URL = process.env.SRC_URL;
const SRC_SERVICE_KEY = process.env.SRC_SERVICE_KEY;
const DST_URL = process.env.DST_URL;
const DST_SERVICE_KEY = process.env.DST_SERVICE_KEY;

if (!SRC_URL || !SRC_SERVICE_KEY || !DST_URL || !DST_SERVICE_KEY) {
  console.error("Defina SRC_URL, SRC_SERVICE_KEY, DST_URL, DST_SERVICE_KEY");
  process.exit(1);
}

const src = createClient(SRC_URL, SRC_SERVICE_KEY, { auth: { persistSession: false } });
const dst = createClient(DST_URL, DST_SERVICE_KEY, { auth: { persistSession: false } });

const tables = [
  { name: "profiles", pkey: "id" },
  { name: "user_audit_log", pkey: "id" },
];

async function copyTable(t) {
  let from = 0;
  const size = 1000;
  for (;;) {
    const to = from + size - 1;
    const { data, error, count } = await src.from(t.name).select("*", { count: "exact" }).range(from, to);
    if (error) throw new Error(`Erro ao ler ${t.name}: ${error.message}`);
    if (!data || data.length === 0) break;
    const { error: werr } = await dst.from(t.name).upsert(data, { onConflict: t.pkey, ignoreDuplicates: false });
    if (werr) throw new Error(`Erro ao escrever ${t.name}: ${werr.message}`);
    from += data.length;
    if (count !== null && from >= count) break;
  }
}

(async () => {
  for (const t of tables) {
    await copyTable(t);
    console.log(`Tabela ${t.name} migrada`);
  }
  console.log("Migração concluída");
})().catch((e) => {
  console.error(e.message);
  process.exit(2);
});
