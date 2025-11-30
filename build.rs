fn main() {
    uniffi::generate_scaffolding("src/bark_ffi.udl")
        .expect("Failed to generate UniFFI scaffolding");
}
