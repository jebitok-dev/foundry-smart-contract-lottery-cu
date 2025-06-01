# Testing

## Commands

``````
$ forge test --mt testRaffleRevertsWHenYouDontPayEnough
$ forge test --mt testRaffleRecordsPlayerWhenTheyEnter
$ forge test --mt testRaffleRecordsPlayersWhenTheyEnter -vvvv
$ forge clean && forge build
$ forge test --mt testEmitsEventOnEntrance
$ forge test --mt testDontAllowPlayersToEnterWhileRaffleIsCalculating
$ forge test --mt testDontAllowPlayersToEnterWhileRaffleIsCalculating -vvvvv
$ forge test --mt testDontAllowPlayersToEnterWhileRaffleIsCalculating -vv
$ forge test --mt testCheckUpkeepReturnsFalseIfItHasNoBalance -vv
$ forge test --mt testCheckUpkeepReturnsFalseIfRaffleIsntOpen -vv
$ forge test --mt testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId
$ forge test --mt testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep
$ forge test --mt testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney 
``````


In my opinion, when one needs to decide where to start testing there are two sensible approaches one could take:

1. Easy to Complex - start with view functions, then with smaller functions and advance to the more complex functions;
2. From the main entry point(s) to the periphery - what is the main functionality that the external user needs to call in order to interact with your contract;


`````
function enterRaffle() external payable {
    if(msg.value < i_entranceFee) revert Raffle__NotEnoughEthSent();
    if (s_raffleState != RaffleState.OPEN) revert Raffle__RaffleNotOpen();

    s_players.push(payable(msg.sender));
    emit EnteredRaffle(msg.sender);

}
`````

1. We check if the `msg.value` is high enough;
2. We check if the `RaffleState` is `OPEN`;
3. If all of the above are `true` then the `msg.sender` should be pushed in the `s_players` array;
4. Our function emits the `EnteredRaffle` event.

To effortlessly create elegant **function** or **section headers** in your contract, you can use the [headers tool](https://github.com/transmissions11/headers) from transmission11. This tool generates code such as:

```js
/*//////////////////////////////////////////////////////////////
                           ENTER RAFFLE
//////////////////////////////////////////////////////////////*/
```
