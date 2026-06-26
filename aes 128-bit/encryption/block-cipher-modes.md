## Why block ciphers?
- provide information security (confidentiality, authenticity).
- more suitable for secure cryptographics tranformation (encry or decryp).


AES 128-bit deals with blocks of size 12b-bits only.
#### Mode of Operation of the block defines how to apply operations to securly transform amounts of data larger than a block.

#### Initialization vector (IV) 
- used to randomasize the encryptionn, providing distinct ciphertexts for the same plaintext.
- must not be re-used i.e IV must be random/pseudorandom (statistically random).

#### Padding
simplest scheme - add null bytes to the plaintext to bring its length up to a multiple of the block size


## Block cipher modes of operation

<img width="831" height="490" alt="image" src="https://github.com/user-attachments/assets/0f4c43b9-a40a-4d4b-9e37-90272282257e" />


### Confidentiality Modes:

| Mode                     | Abbreviation | Formula                                                                 | Note |
|--------------------------|--------------|-------------------------------------------------------------------------|------|
| Electronic Codebook      | ECB          | Yᵢ = F(PlainTextᵢ, Key)                                                 |-  each block encrypted seperately.<br>- not reccomended due to lack of diffusion - produces identical ciphertexts for identical plain texts, failing to hide data patterns |
| Cipher Block Chaining    | CBC          | Yᵢ = PlainTextᵢ XOR Ciphertextᵢ₋₁                                       |  - each block of plaintext is XORed with the previous ciphertext block before being encrypted.<br>-IV is XORed with the first block.<br>- drawback - encryption is sequential (i.e., it cannot be parallelized), and that the message must be padded to a multiple of the cipher block size.<br>- decryption can be parallelized - using incorrect IV.
| Propagating CBC          | PCBC         | Yᵢ = PlainTextᵢ XOR (Ciphertextᵢ₋₁ XOR PlainTextᵢ₋₁)                    |  - each block of plaintext is XORed with both the previous plaintext block and the previous ciphertext block before being encrypted.<br>- IV needed fro first block.<br>- decrypting PCBC with the incorrect IV causes all blocks of plaintext to be corrupt.   |
| Cipher Feedback          | CFB          | Yᵢ = Ciphertextᵢ₋₁                                                      |   - "a block cipher into a self-synchronizing stream cipher"<br>-  changes in the plaintext propagate forever in the ciphertext, and encryption cannot be parallelized.<br>- decryption can be parallelized.   |
| Output Feedback          | OFB          | Yᵢ = F(Yᵢ₋₁, Key); Y₀ = F(IV, Key)                                       |  - " block cipher into a synchronous stream cipher"<br>- keystream blocks, which are then XORed with the plaintext blocks to get the ciphertext.<br>-encryption and decryption are exactly the same - symmetry of XOR operation     |
| Counter                  | CTR          | Yᵢ = F(IV + g(i), Key); IV = token()                                    |  - generates the next keystream block by encrypting successive values of a "counter".<br>- counter produces a sequence which is guaranteed not to repeat for a long time.  |


### AEAD:
*Authenticated encryption with additional data (AEAD) 
These modes 
- combine confidentiality (encryption) and authentication (integrity) in one operation. 
- allow additional data to be authenticated if not encrypted.

### AES-GCM:
(Advanced Encryption Standard with Galois/Counter Mode)



