// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// We will add the Interfaces here
interface IFakeNFTMarketplace {
    /// @dev getPrice() returns the price of an NFT from the FakeNFTMarketplace
    /// @return Returns the price in Wei for an NFT
    function getPrice() external view returns (uint256);

    /// @dev available() returns whether or not the given _tokenId has already been purchased
    /// @return Returns a boolean value - true if available, false if not
    function available(uint256 _tokenId) external view returns (bool);

    /// @dev purchase() purchases an NFT from the FakeNFTMarketplace
    /// @param _tokenId - the fake NFT tokenID to purchase
    function purchase(uint256 _tokenId) external payable;
}

interface ICryptoDevsNFT {
    /// @dev balanceOf returns the number of NFTs owned by the given address
    /// @param owner - address to fetch number of NFTs for
    /// @return Returns the number of NFTs owned
    function balanceOf(address owner) external view returns (uint256);

    /// @dev tokenOfOwnerByIndex returns a tokenID at given index for owner
    /// @param owner - address to fetch the NFT TokenID for
    /// @param index - index of NFT in owned tokens array to fetch
    /// @return Returns the TokenID of the NFT
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

contract CryptoDevsDAO is Ownable {
    // We will write contract code here

    struct Proposal {
        uint256 nftTokenId;
        uint256 deadline;
        uint256 yayVotes;
        uint256 nayVotes;
        bool executed;
        mapping(uint256 => bool) voters;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public numProposals;

    IFakeNFTMarketplace nftMarketPlace;
    ICryptoDevsNFT cryptoDevNFT;

    enum Vote {
        YAY,
        NAY
    }

    constructor(address _nftMarketplaceAddress, address _cryptoDevNFTAddress)
        payable
    {
        nftMarketPlace = IFakeNFTMarketplace(_nftMarketplaceAddress);
        cryptoDevNFT = ICryptoDevsNFT(_cryptoDevNFTAddress);
    }

    modifier nftHoldersOnly() {
        require(cryptoDevNFT.balanceOf(msg.sender) > 0, "NOT a DAO Member");
        _;
    }

    function createProposal(uint256 _nftTokenId)
        external
        nftHoldersOnly
        returns (uint256)
    {
        require(nftMarketPlace.available(_nftTokenId), "NFT_IS_NOT_FOR_SALE");

        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;

        numProposals++;
        return numProposals - 1;
    }

    modifier activeProposalsOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline > block.timestamp,
            "DEADLINE EXCEEDED"
        );
        _;
    }

    function voteProposal(uint256 _proposalIndex, Vote vote)
        external
        nftHoldersOnly
        activeProposalsOnly(_proposalIndex)
    {
        Proposal storage proposal = proposals[_proposalIndex];
        uint256 voterNFTBalance = cryptoDevNFT.balanceOf(msg.sender);
        uint256 numVotes;

        for (uint256 i = 0; i < voterNFTBalance; i++) {
            uint256 tokenId = cryptoDevNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }
        require(numVotes > 0, "ALREADY VOTED");
        if (vote == Vote.YAY) {
            proposal.yayVotes++;
        } else {
            proposal.nayVotes++;
        }
    }

    modifier inactiveProposalsOnly(uint256 _proposalIndex) {
        require(
            proposals[_proposalIndex].deadline <= block.timestamp,
            "DEADLINE_NOT_EXCEEDED"
        );
        require(
            proposals[_proposalIndex].executed == false,
            "PROPOSAL_ALREADY_EXECUTED"
        );
        _;
    }

    function executeProposal(uint256 _proposalIndex)
        external
        nftHoldersOnly
        inactiveProposalsOnly(_proposalIndex)
    {
        Proposal storage proposal = proposals[_proposalIndex];
        if (proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = nftMarketPlace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            nftMarketPlace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}
}
