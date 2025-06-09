const fs = require('node:fs/promises');

async function readFile() {
  const data = await fs.readFile('./data.txt', {encoding: 'utf-8'});
  const lines = data.split(/\n+/);
  const list1 = [];
  const list2 = [];
  for (const line of lines) {
    const ids = line.split(/\s+/);
    if (ids.length === 2) {
      list1.push(ids[0]);
      list2.push(ids[1]);
    }
  }

  list1.sort();
  list2.sort();

  var distance = 0;
  for (var x=0; x<list1.length; x++) {
    distance += Math.abs(list1[x]-list2[x]);
  }

  console.log(distance);
}

readFile();
