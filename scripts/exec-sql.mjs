import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import process from "node:process";
import { Client } from "pg";

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--conn") {
      args.conn = argv[++i];
    } else if (a === "--file") {
      args.file = argv[++i];
    }
  }
  return args;
}

async function main() {
  const args = parseArgs(process.argv);
  const conn = args.conn || process.env.PGDST || process.env.PGURI;
  const file = args.file ? resolve(args.file) : null;
  if (!conn || !file) {
    console.error("Parâmetros ausentes: --conn e --file são obrigatórios");
    process.exit(1);
  }
  const sql = readFileSync(file, "utf8");
  const client = new Client({ connectionString: conn });
  try {
    await client.connect();
    await client.query("begin");
    await client.query(sql);
    await client.query("commit");
    console.log("SQL executado com sucesso");
    process.exit(0);
  } catch (e) {
    try { await client.query("rollback"); } catch {}
    console.error("Erro ao executar SQL:", e.message);
    process.exit(2);
  } finally {
    await client.end().catch(() => {});
  }
}

main();
