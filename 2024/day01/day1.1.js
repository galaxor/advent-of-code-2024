const fs = require('node:fs/promises');

async function readFile() {
  const data = await fs.readFile('./data.txt', {encoding: 'utf-8'});
  const lines = data.split(/\n+/);
  const list1 = [];
  const list2 = {};
  for (const line of lines) {
    const ids = line.split(/\s+/);
    if (ids.length === 2) {
      list1.push(ids[0]);
      const l2num = ids[1];
      if (typeof list2[l2num] === "undefined") {
        list2[l2num] = 0;
      }

      list2[l2num] += 1;
    }
  }

  var similarity = 0;
  for (const num of list1) {
    similarity += num * (list2[num] ?? 0);
  }

  console.log(similarity);
}

readFile();
