use std::io;
use std::io::BufRead;

#[derive(Debug)]
struct CoolValues {
    largest_digit: char,
    next_start_index: usize,
}


fn largest_digit_starting_at_i_excluding_last_n(line: &String, start_index: usize, exclude_count: usize) -> CoolValues {
    let mut line_slice = line[start_index..(line.len() - exclude_count)].to_string().as_bytes().to_vec();
    line_slice.sort();
    let largest_digit = line_slice[line_slice.len()-1] as char;
    let index_of_largest_digit = start_index + line[start_index..].find(largest_digit).unwrap();

    return CoolValues { largest_digit: largest_digit, next_start_index: index_of_largest_digit + 1 };
}

#[derive(Debug)]
struct CoolerValues {
    digits: String,
    start_index: usize,
}

fn line_joltage(line: String, need_digits: usize) -> u64 {
    let x = (0..need_digits).rev().fold(
        CoolerValues { digits: String::from(""), start_index: 0 },
        |state, exclude_count| {
            let cool_values = largest_digit_starting_at_i_excluding_last_n(&line, state.start_index, exclude_count);
            let mut out_digits = state.digits.clone();
            out_digits.push(cool_values.largest_digit);
            return CoolerValues {
                digits: out_digits,
                start_index: cool_values.next_start_index,
            };
        }
    );

    return x.digits.parse().unwrap();
}

fn main() {
    let lines = io::stdin().lock().lines().map(|line| String::from(line.unwrap()));
    println!("{:?}", lines.map(|line| line_joltage(line, 12)).reduce(|acc, x| acc+x).unwrap());
}
