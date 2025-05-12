pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

fn main() {
    println!("Hello, world!");
}

#[cfg(test)]
mod my_tests {
    // Note this useful idiom: importing names from outer (for mod tests) scope.
    use super::*;

    #[test]
    fn test_add() {
        assert_eq!(add(1, 2), 3);
    }
}