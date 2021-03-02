// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

library WoteLibrary {
  struct Ballot {
    string id;
    string secretHash;
  }

  struct Voter {
    address id;
    bool voted;
  }

  struct VoteCandidate {
    address id;
    string name;
  }

  struct CandidateResult {
    address candiateId;
    uint voteCount;
  }

  struct VoteResult {
    uint registeredVoters;
    uint effectiveVoters;
    uint abstensions;
    uint nullVotes;
    uint valableVotes;
    CandidateResult[] results;
  }

  // event VoteCounted (
  //   VoteResult results
  // );
}

/**
1. Unify ballots and claims by add an address field `claimedBy` to Ballot
2. Add a cancel vote feature to cancel the whole vote
3. Add a cancel ballot feature to un-register a ballot and set voter as not voted
**/

contract Wote {
    address public owner = msg.sender;
    mapping(address => WoteLibrary.Voter) public voters;
    mapping(address => WoteLibrary.VoteCandidate) public candidates;
    mapping(string => WoteLibrary.Ballot) ballots; // maybe unify ballots and claims by adding claimee to Ballot struct

    mapping(string => address) claims;
    mapping(address => uint) public results; // address(0) -> bulletin nul
    bool voteStarted;
    bool voteClosed;
    uint startedAt;
    uint closedAt;

    address[] uniqueCandiates;
    address[] uniqueVoters;
    string[] uniqueBallots;

    event VoteCounted (
    WoteLibrary.VoteResult results
  );



    constructor() public {
        owner = msg.sender;
        voteClosed = false;
    }

    modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  modifier closed(bool indicator) {
    require(voteClosed == indicator, "closed indicator should be ");
    _;
  }

  modifier started(bool indicator) {
    require(voteStarted == indicator, "closed indicator should be ");
    _;
  }

  function initiateVote(WoteLibrary.VoteCandidate[] memory _candidates, address[] memory _voters) public restricted {
    require(_candidates.length > 0, "A vote should have at least one candiate");
    require(_voters.length > 0, "A vote should have at least one voter");
    for(uint i=0; i< _candidates.length; i++) {
      WoteLibrary.VoteCandidate memory _candidate = _candidates[i];
      candidates[_candidate.id] = _candidate;
      uniqueCandiates.push(_candidate.id);
    }

    for(uint i=0; i< _voters.length; i++) {
      WoteLibrary.Voter memory _voter = WoteLibrary.Voter(_voters[i], false);
      // _voter.voted = false;
      voters[_voter.id] = _voter;
      uniqueVoters.push(_voter.id);
    }
    voteStarted = false;
    voteClosed = false;
  }

  function startVote() public restricted started(false) closed(false) {
    voteStarted = true;
    startedAt = block.timestamp;
  }

  function closeVote() public restricted started(true) closed(false) {
    voteClosed = true;
    closedAt = block.timestamp;
  }

  function stringComparison(string memory a, string memory b) public pure returns(bool) {
    return keccak256(bytes(a)) == keccak256(bytes(b));
  }

  function createBallot(string memory _bollotId, string memory _secretHash) public closed(false) {
    address voter = msg.sender;
    require(voters[voter].id == voter, "unknown voter");
    require(voters[voter].voted, "already voted");
    require(!stringComparison(ballots[_bollotId].id, _bollotId), "existing ballot with same id");
    ballots[_bollotId] = WoteLibrary.Ballot(_bollotId, _secretHash);
    voters[voter] = WoteLibrary.Voter(voter, true);
    uniqueBallots.push(_bollotId);
  }

  /* we should have piece of information to re-constitute the ballot id from inputs
  We can use for example blind signature, hashing, secret, etc.
  */

  function claimBallot(string memory _bollotId, string memory _secret) public closed(false) {
    address candidate = msg.sender;
    require(candidates[candidate].id == candidate, "not a candidate to claim something");
    require(stringComparison(ballots[_bollotId].id, _bollotId), "not a valid ballot");
    require(claims[_bollotId] == address(0), "already claimed ballot");
    require(keccak256(_secret) == ballots[_bollotId].secretHash, "not a valid ballot");
    claims[bollotId] = candidate;
  }

  function calculateResults() public closed(true) {
    for (uint i=0; i < uniqueBallots.length; i++) {
      string memory _ballotId = uniqueBallots[i];
      address _claimee = claims[_ballotId];
      results[_claimee]++;
    }
    uint totalNumberOfRegisteredVoters = uniqueVoters.length;
    uint totalNumberOfEffectiveVoters = uniqueBallots.length;
    uint numberOfAbstensions = totalNumberOfRegisteredVoters - totalNumberOfEffectiveVoters;
    uint numberOfNullVotes = results[address(0)];
    uint numberOfValableVotes = totalNumberOfEffectiveVoters - numberOfNullVotes;
    WoteLibrary.CandidateResult[] memory candidateResults;
    for (uint i=0; i < uniqueCandiates.length; i++) {
      address _candidate = uniqueCandiates[i];
      candidateResults[i] = WoteLibrary.CandidateResult(_candidate, results[_candidate]);
    }
    WoteLibrary.VoteResult memory _voteResults = WoteLibrary.VoteResult(totalNumberOfRegisteredVoters, totalNumberOfEffectiveVoters,
    numberOfAbstensions, numberOfNullVotes, numberOfValableVotes, candidateResults);
    emit VoteCounted(_voteResults);
  }
}