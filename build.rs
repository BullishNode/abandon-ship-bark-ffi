fn main() {
    uniffi::generate_scaffolding("src/bark.udl").expect("Failed to generate UniFFI scaffolding");
}
