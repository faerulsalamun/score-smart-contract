//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import './base/UniversalChanIbcApp.sol';

contract XBettingUC is UniversalChanIbcApp  {

    enum IbcPacketStatus {UNSENT, SENT, ACKED, TIMEOUT}
    address public admin;

    struct PlayerBettingMatch {
       uint256 scoreOne;
       uint256 scoreTwo;
    }

    struct Team {
        string name; 
        string logo;  
    }

    struct Match {
        Team teamOne;   
        Team teamTwo;
        string link;
        string schedule;
        uint256 scoreOne;   
        uint256 scoreTwo;
        bool reveal;
    }

    struct UserPoint {
        address user;
        uint256 point;
        IbcPacketStatus ibcPacketStatus;
        uint256 nftId;    
    }

    Match[] public matches;

    mapping(address => UserPoint) public userWinners;
    mapping(address => PlayerBettingMatch[]) public playerBets;
    mapping(address => uint256) public playerPoints;
    address[] public participants;
    bool public isReveal = false;

    event AckNFTMint(address indexed destPortAddr, address indexed user, uint nftId);

    constructor(
        address _middleware,
        address _admin
    ) UniversalChanIbcApp(_middleware) {
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "The caller is not admin.");
        _;
    }

    function addMatches(
        Match[] calldata _matches
    ) external {

        for (uint256 i=0; i <_matches.length; i++) {
            matches.push(_matches[i]);
        }
    }

    function betting(
        PlayerBettingMatch[] calldata _playerBettingMatches
    ) external {
        require(_playerBettingMatches.length > 0, "No betting matches provided");
        require(playerBets[msg.sender].length == 0, "Already betting");
        require(_playerBettingMatches.length == matches.length, "Length betting is different from match");

        participants.push(msg.sender);

        for (uint256 i = 0; i < _playerBettingMatches.length; i++) {
            playerBets[msg.sender].push(PlayerBettingMatch(_playerBettingMatches[i].scoreOne,_playerBettingMatches[i].scoreTwo));
        }
    }

    function getMatches() public view returns(Match[] memory) {
        return matches;
    }

    function getPlayerPoints() public view returns(address[] memory, uint[] memory) {
        address[] memory users = new address[](participants.length);
        uint256[] memory points = new uint256[](participants.length);

        for (uint256 i = 0; i < participants.length; i++) {
            users[i] = participants[i];
            points[i] = playerPoints[participants[i]];
        }

        return (users, points);
    }

    function getPlayerBet(address _player) public view returns(PlayerBettingMatch[] memory) {
        return playerBets[_player];
    }

    function calculateScore() internal {
        // Loop participant 
        for (uint256 i = 0; i < participants.length; i++) {
            // Loop playerBets
            for (uint256 x = 0; x < playerBets[participants[i]].length; x++) {
                if(matches[x].scoreOne == playerBets[participants[i]][x].scoreOne &&
                    matches[x].scoreTwo == playerBets[participants[i]][x].scoreTwo) {
                    playerPoints[participants[i]] += 1;
                }
            }
        }
    }

    function reveal(
        address destPortAddr,
        bytes32 channelId, 
        uint64 timeoutSeconds
    ) external onlyAdmin{
        require(!isReveal, "Already reveal this match");

        for (uint256 i = 0; i < matches.length; i++) {
            uint256 randomNumberOne = uint256(keccak256(abi.encodePacked(block.timestamp + i, block.prevrandao + i, blockhash(block.number - i)))) % 5;
            uint256 randomNumberTwo = uint256(keccak256(abi.encodePacked(block.timestamp + i+2, block.prevrandao + i+2, blockhash(block.number - i+2)))) % 5;

            // For testing only
            // uint256 randomNumberOne = 1;
            // uint256 randomNumberTwo = 2;

            matches[i].scoreOne = randomNumberOne + 1;
            matches[i].scoreTwo = randomNumberTwo + 1;
            matches[i].reveal = true;
        }

        calculateScore(); 

        // Prepare for send NFT to top 10
        uint256 totalSend = 0;
        UserPoint[] memory userPoints = calculateHighestPoints();

        for (uint256 i = 0; i < userPoints.length; i++) {
            if(userPoints[i].point > 0 ){
                userWinners[userPoints[i].user] = userPoints[i];
                require(userWinners[userPoints[i].user].ibcPacketStatus == IbcPacketStatus.UNSENT || userWinners[userPoints[i].user].ibcPacketStatus == IbcPacketStatus.TIMEOUT, "An IBC packet relating to his vote has already been sent. Wait for acknowledgement.");

                bytes memory payload = abi.encode(userWinners[userPoints[i].user].user);
                uint64 timeoutTimestamp = uint64((block.timestamp + timeoutSeconds) * 1000000000);

                IbcUniversalPacketSender(mw).sendUniversalPacket(
                    channelId,
                    IbcUtils.toBytes32(destPortAddr),
                    payload,
                    timeoutTimestamp
                );
                userWinners[userPoints[i].user].ibcPacketStatus = IbcPacketStatus.SENT;
                    
                totalSend++;
            }

            if (totalSend > 10){
                break;
            }
        }

        isReveal = true;
    }

    function onRecvUniversalPacket(
        bytes32,
        UniversalPacket calldata
    ) external override view onlyIbcMw returns (AckPacket memory ackPacket) {
        require(false, "This function should not be called");

        return AckPacket(true, abi.encode("Error: This function should not be called"));
    }

    function onUniversalAcknowledgement(
            bytes32 channelId,
            UniversalPacket memory packet,
            AckPacket calldata ack
    ) external override onlyIbcMw {
        ackPackets.push(UcAckWithChannel(channelId, packet, ack));

        // decode the ack data, find the address of the voter the packet belongs to and set ibcNFTMinted true
        (address user, uint256 nftId) = abi.decode(ack.data, (address, uint256));
        userWinners[user].ibcPacketStatus = IbcPacketStatus.ACKED;
        userWinners[user].nftId = nftId;

        emit AckNFTMint(IbcUtils.toAddress(packet.destPortAddr), user, nftId);
    }

    function onTimeoutUniversalPacket(
        bytes32 channelId, 
        UniversalPacket calldata packet
    ) external override onlyIbcMw {
        timeoutPackets.push(UcPacketWithChannel(channelId, packet));
        // Timeouts not currently supported
    }

    function getLeaderboard() public view returns (UserPoint[] memory) {
        return calculateHighestPoints();
    }

    function checkWinner(address _address) public view returns (UserPoint memory) {
        return userWinners[_address];
    }

    function calculateHighestPoints() internal view returns(UserPoint[] memory) {
        UserPoint[] memory userPoints = new UserPoint[](participants.length);

        // Populate userPoints array
        for (uint256 i = 0; i < participants.length; i++) {
            userPoints[i].user = participants[i];
            userPoints[i].point = playerPoints[participants[i]];
        }

        // Sort the userPoints array in descending order based on points
        for (uint256 i = 0; i < userPoints.length; i++) {
            for (uint256 j = i + 1; j < userPoints.length; j++) {
                if (userPoints[j].point > userPoints[i].point) {
                    // Swap the userPoints
                    UserPoint memory temp = userPoints[i];
                    userPoints[i] = userPoints[j];
                    userPoints[j] = temp;
                }
            }
        }

        return userPoints;
    }
}