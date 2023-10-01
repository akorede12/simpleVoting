pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED

// Develop a basic smart contract for a voting system that allows only
// registered members to vote and deploy it on Swisstronik testnet.

// Requirements:
// Ensure that all state variables are private
// Create a smart contract for the voting system
// Implement a function for the contract owner to register new voters
// Allow only the contract owner to add new voters  X
// Create a modifier (e.g. onlyVoter) or a function to check that only
// registered voters can interact with the contract. Apply this check to all voting-related functions
// Develop functions for registered voters to cast their votes
// Create a function to retrieve the current vote count

contract Voting {
    string private electionName;

    address private electionCreator; // The contract owner

    mapping(address => bool) private voters; // mapping to store all voters
    mapping(address => uint) private votes; // mapping to store all votes

    // An array of options available for users to vote
    string[] private voteOptions;

    // An array of registered voters
    address[] private allowedVoters;

    // Struct to keep track of voters and thier votes
    struct voterAndVotes {
        address validVoter;
        uint votedFor;
    }

    // Struct to keep track of vote options and thier vote count
    struct votesForVoteOptions {
        string voteOption;
        uint voteCount;
    }

    constructor(string memory _electionName) {
        electionCreator = msg.sender;
        electionName = _electionName;
    }

    // Modifier to prevent none owner access
    modifier onlyOwner() {
        require(msg.sender == electionCreator, "Caller is not authorized.");
        _;
    }

    // modifier to prevent none voter access
    modifier onlyVoter() {
        require(voters[msg.sender], "voter is not registered.");
        _;
    }

    event newVote(address voter, string voteOption);

    event newVoterAdded(address[] voterAddress);

    event voterRemoved(address voterAddress);

    event addedVoteOption(string voteOption);

    // function to modify election name
    function changeElectionDetail(
        string memory _electionName
    ) public onlyOwner returns (string memory, address) {
        electionName = _electionName;
        return (electionName, electionCreator);
    }

    function getElectionDetails()
        public
        view
        onlyOwner
        onlyVoter
        returns (string memory, address)
    {
        return (electionName, electionCreator);
    }

    function addAllowedVoter(address newVoter) internal {
        allowedVoters.push(newVoter);
    }

    // function to register voters, onlyowner restricted
    function registerVoter(address[] memory newVoter) public onlyOwner {
        for (uint i = 0; i < newVoter.length; i++) {
            if (!voters[newVoter[i]]) {
                voters[newVoter[i]] = true;

                addAllowedVoter(newVoter[i]);
            } else {
                revert("Voter already registered");
            }
        }

        emit newVoterAdded(newVoter);
    }

    // function to view the registered voters
    function viewVoters() public view onlyOwner returns (address[] memory) {
        return (allowedVoters);
    }

    // function to unregister voters
    function unregisterVoter(address voter) public onlyOwner {
        require(voters[voter]);
        voters[voter] = false;

        for (uint i = 0; i < allowedVoters.length; i++) {
            if (allowedVoters[i] == voter) {
                allowedVoters[i] = allowedVoters[allowedVoters.length - 1];
                allowedVoters.pop();
            }
        }
        emit voterRemoved(voter);
    }

    function addOption(string memory option) internal {
        for (uint i = 0; i < voteOptions.length; i++) {
            require(
                keccak256(bytes(voteOptions[i])) != keccak256(bytes(option)),
                "Option already exists."
            );
        }
        voteOptions.push(option);
        emit addedVoteOption(option);
    }

    // voteOption represents the candidates in the election.
    // internal function to add voteOptions to the elections
    function addVoteOptions(string[] memory newOptions) public onlyOwner {
        for (uint i = 0; i < newOptions.length; i++) {
            addOption(newOptions[i]);
        }
    }

    function viewVoteOptions()
        public
        view
        onlyOwner
        onlyVoter
        returns (string[] memory)
    {
        return (voteOptions);
    }

    // castVotes
    function castVote(string memory option) public onlyVoter {
        // check if voter has voted
        require(votes[msg.sender] == 0, " Voter has already voted.");
        // use checker library to check if user option is valid
        isValidOption(voteOptions, option);
        // get the index of the options in voteOptions array
        uint optionIndex = getOptionIndex(voteOptions, option);
        // update votes mapping
        votes[msg.sender] = optionIndex + 1;
        emit newVote(msg.sender, option);
    }

    // Function to get all the votes, and the respective voters.
    function getVotes()
        public
        view
        onlyOwner
        onlyVoter
        returns (voterAndVotes[] memory)
    {
        // uint variable to keep track of dynamic array
        uint voterVoteCount = 0;
        // for loop to iterate through the allowedVoters arrays,
        // for loop to chack if the users gotten from the allowedVoters have voted, with votes mapping
        for (uint i = 0; i < allowedVoters.length; i++) {
            // check
            if (voters[allowedVoters[i]] == true) {
                voterVoteCount++;
            }
        }

        voterAndVotes[] memory voterVotesArray = new voterAndVotes[](
            voterVoteCount
        );

        uint count = 0;

        // for loop to iterate through the allowedVoters arrays,
        // for loop to check if the users gotten from the allowedVoters have voted, with votes mapping
        for (uint i = 0; i < allowedVoters.length; i++) {
            // check
            if (voters[allowedVoters[i]] == true) {
                address currentVoter = allowedVoters[i];
                uint currentVote = votes[currentVoter];

                voterVotesArray[count] = voterAndVotes(
                    currentVoter,
                    currentVote
                );
                count++;
            }
        }
        return voterVotesArray;
    }

    // Function to get the vote count for a vote option
    function getVoteOptionVoteCount(
        string memory option
    ) public view onlyOwner returns (uint) {
        // use checker library to check if user option is valid
        isValidOption(voteOptions, option);
        // get the index of the options in voteOptions array
        uint optionIndex = getOptionIndex(voteOptions, option);
        // Add one to option index to prevent index from starting from 0
        optionIndex + 1;

        // variable to keep track of vote count
        uint voteCount = 0;

        // votes[msg.sender] = optionIndex + 1;
        // for loop to loop through allowedVoters array and votes mapping
        for (uint i = 0; i < allowedVoters.length; i++) {
            if (votes[allowedVoters[i]] == optionIndex + 1) {
                voteCount++;
            }
        }
        return voteCount;
    }

    function getElectionWinner()
        public
        view
        onlyOwner
        onlyVoter
        returns (string memory)
    {
        // struct array of votes and vote Options
        votesForVoteOptions[]
            memory votesForVoteOptionsArray = new votesForVoteOptions[](
                voteOptions.length
            );

        // loop count
        uint count = 0;

        for (uint i = 0; i < voteOptions.length; i++) {
            string memory currentOption = voteOptions[i];
            uint optionVoteCount = getVoteOptionVoteCount(voteOptions[i]);
            votesForVoteOptionsArray[count] = votesForVoteOptions(
                currentOption,
                optionVoteCount
            );

            count++;
        }

        // Find the option with the highest vote count
        string memory winner = "";
        uint maxVotes = 0;
        bool isTie = false;
        for (uint i = 0; i < votesForVoteOptionsArray.length; i++) {
            if (votesForVoteOptionsArray[i].voteCount > maxVotes) {
                maxVotes = votesForVoteOptionsArray[i].voteCount;
                winner = votesForVoteOptionsArray[i].voteOption;
                isTie = false;
            } else if (votesForVoteOptionsArray[i].voteCount == maxVotes) {
                isTie = true;
            }
        }

        if (isTie) {
            return "Tie between top vote options";
        } else {
            return winner;
        }
    }

    // Auxillary functions
    function isValidOption(
        string[] memory _voteOptions,
        string memory option
    ) public pure {
        uint optionIndex;
        for (uint i = 0; i < _voteOptions.length; i++) {
            if (
                keccak256(abi.encodePacked(_voteOptions[i])) ==
                keccak256(abi.encodePacked(option))
            ) {
                optionIndex = i;
                break;
            }
        }
        require(
            keccak256(abi.encodePacked(_voteOptions[optionIndex])) ==
                keccak256(abi.encodePacked(option)),
            "Option is not valid"
        );
    }

    function getOptionIndex(
        string[] memory _voteOptions,
        string memory option
    ) public pure returns (uint8) {
        for (uint8 i = 0; i < _voteOptions.length; i++) {
            if (
                keccak256(abi.encodePacked(_voteOptions[i])) ==
                keccak256(abi.encodePacked(option))
            ) {
                return i;
            }
        }
        revert("Invalid vote option.");
    }
}
