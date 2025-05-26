# Foundry Smart Contract Lottery CU



## Proveably Random Raffle Contracts

## About

This code is to create a proveably random smart contract lottery.

## What we want it to do?

1. Users should be able to enter the raffle by paying for a ticket. The ticket fees are going to be the prize the winner receives.
2. The lottery should automatically and programmatically draw a winner after a certain period.
3. Chainlink VRF should generate a provably random number.

4. Chainlink Automation should trigger the lottery draw regularly.

## What did we do?

* We implemented Chainlink VRF to get a random number

* We defined a couple of variables that we need both for Raffle operation and for Chainlink VRF interaction

* We have a not-so-small constructor

* We created a method for the willing participants to enter the Raffle

* Then made the necessary integrations with Chainlink Automation to automatically draw a winner when the time is right.

* When the time is right and after the Chainlink nodes perform the call then Chainlink VRF will provide the requested randomness inside `fulfillRandomWords`

* The randomness is used to find out who won, the prize is sent, raffle is reset.

<br />
