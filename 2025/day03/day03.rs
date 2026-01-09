use std::io;
use std::io::BufRead;

fn main() {
    let lines = io::stdin().lock().lines().map(|line| String::from(line.unwrap()));
    
    let total_joltage: u64 = lines.map(|line| {
        let mut line_without_last_char = line[0..(line.len() - 1)].as_bytes().to_vec();
        line_without_last_char.sort();
        let largest = line_without_last_char[line_without_last_char.len()-1] as char;
        let index_of_largest = line.find(largest).unwrap();
        let mut remainder = line[(index_of_largest+1)..].as_bytes().to_vec();
        remainder.sort();
        let second_largest = remainder[remainder.len()-1] as char;
        let line_joltage: u64 = vec![largest, second_largest].into_iter().collect::<String>().parse().unwrap();
        return line_joltage;
    }).reduce(|acc, x| acc+x).unwrap();

    println!("{:?}", total_joltage);
}
