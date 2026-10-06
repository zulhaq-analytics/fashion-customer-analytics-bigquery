// Raw H&M tables loaded from Kaggle by scripts/load_raw.ps1.
// Declarations let models reference them with ref() and show them in the graph.
const rawTables = ["articles", "customers", "transactions"];

rawTables.forEach((name) => {
  declare({
    database: "fashion-cx",
    schema: "hm_raw",
    name: name,
  });
});
