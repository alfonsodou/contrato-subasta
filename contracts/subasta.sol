// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Subasta {
    address public owner = 0xF55301514c27489Fde7C9cd9A3EA8044E7E04579;
    string  public description;
    uint256 public minBids;
    uint256 public deadLine;

    mapping (address => uint256) bids;
    address[] public participants;

    constructor (string memory _description, uint256 _minBids, uint256 _minutes) {
        description = _description;
        minBids = _minBids;
        deadLine = block.timestamp + _minutes * 1 minutes;
    }    

    function makeBid () external payable {
        require(block.timestamp < deadLine, "Subasta finalizada!");
        require(bids[msg.sender] == 0, "Ya hiciste una oferta");
        require(msg.sender != owner, "No puedes ofertar a tu propia subasta");
        require(msg.value >= minBids, "Oferta minima no alcanzada");
        require(topBid() < msg.value, "Tu oferta no es la mas alta");
        require(msg.sender.balance > 0.01 ether + msg.value, "Sin saldo");

        bids[msg.sender] = msg.value;
        participants.push(msg.sender);
    }

    function topBid() public view returns (uint256) {
        uint256 max = 0;
        for(uint256 i = 0; i < participants.length; i++) {
            if (bids[participants[i]] > max) {
                max = bids[participants[i]];
            }
        }

        return max;
    }
}