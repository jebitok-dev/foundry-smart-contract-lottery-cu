# Foundry Smart Contract Lottery CU

## Setup & Commands
`````
$ forge init --force
$ forge install smartcontractkit/chainlink@42c74fcd30969bca26a9aadc07463d1c2f473b8c
$ forge remappings>remappings.txt
$ forge build
$ forge test --mt testRaffleInitializesInOpenState -vv
 
`````

- Check path: `foundry-smart-contract-lottery-cu/lib/chainlink/contracts/src/v0.8/vrf/`

## Chainlink & Solidity Quizes
- What primary function does Chainlink VRF (Verifiable Random Function) serve for smart contracts? `To provide a secure and verifiable source of randomness.`
- After a Chainlink oracle generates the requested random number and proof for a VRF request, what is the next step involving the smart contract? `The oracle calls a designated callback function (e.g., ``fulfillRandomWords``) on the consuming contract, delivering the results.`
- When configuring a request for data from an external source that depends on blockchain state (like a VRF request), what is the main trade-off associated with increasing the required number of block confirmations before processing the request? `Increased security against potential blockchain reorganizations at the cost of longer waiting times for the result.`
- How does a smart contract typically initiate a request for random numbers using Chainlink VRF V2? `By calling the `requestRandomWords` function on the VRF Coordinator contract instance.`
- When using the Foundry development framework, what command is typically used to download and install external smart contract dependencies like the Chainlink library? `forge install <repository>`
- In secure callback patterns for smart contracts interacting with external systems, why might an `external` function be used to receive the initial callback before invoking an `internal` function containing the core logic? `To perform security checks, such as verifying that the caller is the expected authorized external source, before executing the main logic.`
- Given the expression `25 % 7`, what is the resulting value? `4`
- If a random number `r` is used with the modulo operator and the length `L` of an array (i.e., `r % L`), what is the range of possible outcomes? `0 to L-1`
- When programmatically triggering a value transfer using a low-level call mechanism that returns a success status, what is the most critical next step? `Verify the success status return value before proceeding.`
- When designing a system that progresses through several distinct phases, what programming construct helps improve code clarity and reduce errors compared to using multiple simple true/false flags? `Enumerations (enums)`
- In a smart contract that uses time intervals to control phases (for example, rounds of a raffle or lottery), how should the start time for a new phase typically be recorded? `Update a timestamp state variable to the current block's timestamp.`
- How can a dynamic array of addresses (`address payable[]`) most efficiently be effectively reset to an empty state within a Solidity smart contract? `By assigning a new, empty array instance to the variable (e.g., ``variableName = new address payable[](0);``).`
- What is the primary function of emitting an event, such as `PickedWinner(address winner)`, from a Solidity smart contract? `To log significant occurrences or state changes, making this data accessible to off-chain services or user interfaces.`
- What is the practice of restructuring existing computer code to improve its readability or efficiency, without changing its external behavior? `Refactoring`
- What is the recommended sequence for structuring operations within a Solidity function to prevent reentrancy? `First Checks, then Effects, followed by Interactions.`
- The Checks-Effects-Interactions (CEI) pattern is a widely recognized best practice primarily designed to mitigate which specific type of smart contract vulnerability? `Reentrancy attacks`
- In the context of the CEI pattern, during which phase would calls to external contracts or transfers of Ether occur? `Interactions`