pragma solidity '0.7.0';

contract WoteERC20 {
    struct Voter {
        bool isVoter;
        uint weight;
        bool voted;
    }

    struct Candidate {
        bool isCandidate;
        uint votes;
    }
    string aName;
    string aSymbol;
    mapping(address => Voter) voters;
    mapping(address => Candidate) candidates;
    uint numberOfVoters;
    mapping(address => mapping(address => uint)) allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(string memory _name, string memory _symbol, address[] memory _voters, address[] memory _candidates) {
        aName = _name;
        aSymbol = _symbol;
        numberOfVoters = _voters.length;
        for (uint index = 0; index < _voters.length; index++) {
            voters[_voters[index]] = Voter(true, 1, false);
        }
        for (uint _index = 0; _index < _candidates.length; _index++) {
            candidates[_candidates[_index]] = Candidate(true, 0);
        }
    }

    function _isVoter(address test) public view returns (bool) {
        return voters[test].isVoter;
    }

    function _hasVoted(address test) public view returns (bool) {
        return voters[test].voted;
    }

    function _isCandidate(address test) public view returns (bool) {
        return candidates[test].isCandidate;
    }


    function name() public view returns (string memory) {
        return aName;
    }

    function symbol() public view returns (string memory) {
        return aSymbol;
    }

    function decimals() public pure returns (uint8) {
        return 0;
    }

    function totalSupply() public view returns (uint256) {
        return numberOfVoters;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        if (_isCandidate(_owner)) {
            return candidates[_owner].votes;
        }
        if (_isVoter(_owner) && !_hasVoted(_owner)) {
            return voters[_owner].weight;
        }
        return 0;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        return _transfer(msg.sender, _to, _value);
    }

    /**
        Transferring vote rights to other than candidates and voters is considered as burning votes.
     */
    function _transfer(address _from, address _to, uint256 _value) public returns (bool success) {
        address voter = _from;
        require(_isVoter(voter), "Only registred voters can cast a vote.");
        require(!_hasVoted(voter), "Already voted.");
        require(_value == voters[voter].weight, "Votes are not splitable. You should transfer your whole rights.");
        address receiver = address(0);
        if (_isCandidate(_to)) {
            candidates[_to].votes += _value;
        }
        else {
            if (_isVoter(_to)) {
                require(!_hasVoted(_to), "Cannot transfer rights to someone who already voted.");
                voters[_to].weight += _value;
                receiver = _to;
            }
        }
        voters[voter].voted = true;
        voters[voter].weight -= _value;
        emit Transfer(voter, receiver, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        address _spender = msg.sender;
        require(_isCandidate(_spender) || _isVoter(_spender), "Only vote actors (voters and candidates) can claim votes on behalf of voters");
        /*
        if (_isCandidate(_spender)) {
            require(_to == _spender || !_isCandidate(_to), "Candidate can only claim vote for himself or burn it. But not for other candidates");
        }
        */
        require(allowance(_from, _spender) >= _value, "You need to be authorized by user to cast vote on his behalf");
        _transfer(_from, _to, _value);
        allowances[_from][msg.sender] -= _value;
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        address _owner = msg.sender;
        require(_isVoter(_owner), "Only registred voters can give allowances");
        require(!_hasVoted(_owner), "Cannot give allowance after casted your vote");
        require(_isCandidate(_spender) || _isVoter(_spender), "Allowances are only for vote actors (voters and candidates).");
        require(_owner != _spender, "Cannot give allowance to yourself");
        allowances[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
}