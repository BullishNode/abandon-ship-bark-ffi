fn main() {
    #[cfg(feature = "uniffi-bindings")]
    uniffi::generate_scaffolding("src/bark.udl").expect("Failed to generate UniFFI scaffolding");
}
