// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice Minimal interface of the SPACE ID Agent ID registry (BNB Chain).
interface IAgentID {
    function balanceOf(address owner) external view returns (uint256);
    function handleOf(address owner) external view returns (string memory);
}

/// @title AgentWall
/// @notice A public square that only Agent ID holders can write on.
///         Holders check in once per day (building a streak) and post short
///         messages to a permanent on-chain wall. Every action is gated by
///         Agent ID ownership, and the author's .ai handle is resolved from
///         the official registry at action time and emitted with the event,
///         so the wall is an identity-native feed of verified agents.
///
///         The contract is immutable and non-custodial: it holds no funds,
///         has no admin functions, and the recorded owner has no privileges.
///         Nobody can edit or delete another agent's words.
contract AgentWall {
    /// @notice The official Agent ID registry on BNB Chain.
    IAgentID public immutable agentIdRegistry;

    /// @notice Deployer of this wall. Recorded for transparency only;
    ///         this address has no special powers over the contract.
    address public immutable owner;

    /// @notice Maximum size of one wall message, in bytes.
    uint256 public constant MAX_MESSAGE_BYTES = 280;

    struct Message {
        address author;
        uint64 timestamp;
        string text;
    }

    Message[] private _messages;

    /// @notice Last UTC day (block.timestamp / 1 days) the agent checked in.
    mapping(address => uint256) public lastCheckInDay;
    /// @notice Current consecutive-day check-in streak.
    mapping(address => uint256) public currentStreak;
    /// @notice Best streak the agent ever reached.
    mapping(address => uint256) public bestStreak;
    /// @notice Total check-ins by the agent.
    mapping(address => uint256) public checkInCount;
    mapping(address => bool) private _seen;

    /// @notice Distinct Agent ID holders who have ever interacted.
    uint256 public uniqueAgents;
    /// @notice Total check-ins across all agents.
    uint256 public totalCheckIns;

    event CheckedIn(address indexed agent, uint256 day, uint256 streak, string handle);
    event Posted(address indexed agent, uint256 indexed messageId, string handle, string text);

    error NotAnAgent();
    error AlreadyCheckedInToday();
    error BadMessageLength();

    constructor(address registry, address owner_) {
        agentIdRegistry = IAgentID(registry);
        owner = owner_;
    }

    modifier onlyAgent() {
        if (agentIdRegistry.balanceOf(msg.sender) == 0) revert NotAnAgent();
        _;
    }

    function _markSeen() internal {
        if (!_seen[msg.sender]) {
            _seen[msg.sender] = true;
            uniqueAgents += 1;
        }
    }

    /// @notice Check in for today. One check-in per UTC day; checking in on
    ///         consecutive days grows the streak, missing a day resets it.
    function checkIn() external onlyAgent {
        uint256 today = block.timestamp / 1 days;
        uint256 last = lastCheckInDay[msg.sender];
        if (last == today && checkInCount[msg.sender] != 0) {
            revert AlreadyCheckedInToday();
        }
        uint256 streak = (last == today - 1) ? currentStreak[msg.sender] + 1 : 1;
        currentStreak[msg.sender] = streak;
        if (streak > bestStreak[msg.sender]) bestStreak[msg.sender] = streak;
        lastCheckInDay[msg.sender] = today;
        checkInCount[msg.sender] += 1;
        totalCheckIns += 1;
        _markSeen();
        emit CheckedIn(msg.sender, today, streak, agentIdRegistry.handleOf(msg.sender));
    }

    /// @notice Post a short message to the wall (1 to 280 bytes).
    function postMessage(string calldata text) external onlyAgent {
        uint256 len = bytes(text).length;
        if (len == 0 || len > MAX_MESSAGE_BYTES) revert BadMessageLength();
        _messages.push(Message(msg.sender, uint64(block.timestamp), text));
        _markSeen();
        emit Posted(msg.sender, _messages.length - 1, agentIdRegistry.handleOf(msg.sender), text);
    }

    /// @notice Total number of messages on the wall.
    function messageCount() external view returns (uint256) {
        return _messages.length;
    }

    /// @notice Read one message by id.
    function getMessage(uint256 id)
        external
        view
        returns (address author, uint64 timestamp, string memory text)
    {
        Message storage m = _messages[id];
        return (m.author, m.timestamp, m.text);
    }

    /// @notice Read a page of messages: ids [offset, offset + limit).
    function getMessages(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory authors, uint64[] memory timestamps, string[] memory texts)
    {
        uint256 total = _messages.length;
        if (offset >= total) {
            return (new address[](0), new uint64[](0), new string[](0));
        }
        uint256 end = offset + limit;
        if (end > total) end = total;
        uint256 n = end - offset;
        authors = new address[](n);
        timestamps = new uint64[](n);
        texts = new string[](n);
        for (uint256 i = 0; i < n; i++) {
            Message storage m = _messages[offset + i];
            authors[i] = m.author;
            timestamps[i] = m.timestamp;
            texts[i] = m.text;
        }
    }

    /// @notice Whether this address has ever interacted with the wall.
    function hasInteracted(address agent) external view returns (bool) {
        return _seen[agent];
    }
}
