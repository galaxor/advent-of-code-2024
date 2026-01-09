use std::io;
use std::io::BufRead;

fn is_repeated_digits(num_str: String) -> bool {
    (1..((num_str.len()/2)+1)).filter(|width| num_str.len() % width == 0)
        .map(|width| {
             let mut chunks = (0..(num_str.len()/width)).map(|index|
                                                             num_str[index*width..(width*(index+1))].to_string()
                                                            );
             let first_chunk = chunks.next().unwrap();
             return chunks.filter(|chunk| *chunk != first_chunk).count() == 0;
        })
        // So we have an iterator that, for each possible width, tells us if that produces an
        // invalid string that's just a bunch of repeated digits.
        // The entire string is invalid if any width produces an invalid string.
        .any(|x| x == true)
}

fn is_invalid(num: &u64) -> bool {
    let num_str = num.to_string();
    num_str.as_bytes()[0] as char == '0'
        || is_repeated_digits(num_str.clone())
}

fn find_invalid_nums(range_start: u64, range_end: u64) -> impl Iterator<Item = u64> {
    return (range_start..(range_end+1)).filter(is_invalid);
}

fn parse_range(range_str: &str) -> (u64, u64) {
    let range_startend: Vec<u64> = range_str.split('-').map(|s: &str| -> u64 { s.parse().unwrap() }).collect();
    return (range_startend[0], range_startend[1]);
}

fn main() {
    let mut input = String::new();
    io::stdin().read_line(&mut input).unwrap();

    let invalid_nums = input.trim().split(',').map(parse_range).flat_map(|(range_start, range_end)| find_invalid_nums(range_start, range_end));

    println!("{}", invalid_nums.reduce(|acc, x| acc + x).unwrap());

    return ();
}
