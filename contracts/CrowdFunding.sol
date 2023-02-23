pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract CrowdFunding is OwnableUpgradeable {
    event ProjectCreated(
        uint256 id,
        address owner,
        string name,
        string description,
        uint256 goal,
        uint256 deadline,
        address paymentToken
    );
    event ProjectFunded(uint256 id, address funder, uint256 amount);
    event ProjectCompleted(uint256 id);
    event SuccesfulProjectWithdraw(uint256 id, address owner, uint256 amount);
    event FailedProjectWithdraw(uint256 id, address funder, uint256 amount);

    error NotTheOwner();

    struct Project {
        address owner;
        string name;
        string description;
        uint256 goal;
        uint256 deadline;
        uint256 amount;
        address paymentToken;
        bool completed;
    }

    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(address => uint256)) public contributions;
    mapping(address => bool) public whitelistedTokens;

    using Counters for Counters.Counter;
    Counters.Counter public projectCounter;

    function initilize() public initializer {
        __Ownable_init();
    }

    //admint functions
    function whitelistToken(address _token) public {
        if (msg.sender != owner()) revert NotTheOwner();
        whitelistedTokens[_token] = true;
    }

    //modifier functions
    modifier onlyWhitelistedToken(address _token) {
        require(whitelistedTokens[_token] == true, "Token is not whitelisted");
        _;
    }

    function createProject(
        string memory _name,
        string memory _description,
        uint256 _goal,
        uint256 _deadline,
        address _paymentToken
    ) public onlyWhitelistedToken(_paymentToken) {
        projectCounter.increment();
        uint256 id = projectCounter.current();

        projects[id] = Project(
            msg.sender,
            _name,
            _description,
            _goal,
            _deadline,
            0,
            _paymentToken,
            false
        );
        emit ProjectCreated(
            id,
            msg.sender,
            _name,
            _description,
            _goal,
            _deadline,
            _paymentToken
        );
    }

    //mutative functions
    function fundProject(uint256 _id, uint256 _amount) public {
        Project storage project = projects[_id];
        require(
            project.deadline > block.timestamp,
            "Project deadline has passed"
        );
        require(project.completed == false, "Project has been completed");
        IERC20 paymentToken = IERC20(project.paymentToken);
        paymentToken.transferFrom(msg.sender, address(this), _amount);
        project.amount += _amount;
        contributions[_id][msg.sender] += _amount;
        if (project.amount >= project.goal) {
            project.completed = true;
            emit ProjectCompleted(_id);
        }
        emit ProjectFunded(_id, msg.sender, _amount);
    }

    function withdrawFunds(uint256 _id) public {
        Project storage project = projects[_id];
        require(project.completed == true, "Project has not been completed");
        require(
            msg.sender == project.owner,
            "Only the owner can withdraw funds"
        );
        IERC20 paymentToken = IERC20(project.paymentToken);
        paymentToken.transfer(project.owner, project.amount);
        emit SuccesfulProjectWithdraw(_id, msg.sender, project.amount);
    }

    function failedFundingWithdraw(uint256 _id) public {
        Project storage project = projects[_id];
        require(project.completed == false, "Project has been completed");
        require(
            project.deadline > block.timestamp,
            "Project deadline has not passed"
        );
        IERC20 paymentToken = IERC20(project.paymentToken);
        uint256 amount = contributions[_id][msg.sender];
        contributions[_id][msg.sender] = 0;
        paymentToken.transfer(msg.sender, amount);
        emit FailedProjectWithdraw(_id, msg.sender, amount);
    }

    //view functions
    function getProject(uint256 _id) public view returns (Project memory) {
        return projects[_id];
    }

    function getOwner(uint256 _id) public view returns (address) {
        return projects[_id].owner;
    }

    function getName(uint256 _id) public view returns (string memory) {
        return projects[_id].name;
    }

    function getDescription(uint256 _id) public view returns (string memory) {
        return projects[_id].description;
    }

    function getGoal(uint256 _id) public view returns (uint256) {
        return projects[_id].goal;
    }

    function getDeadline(uint256 _id) public view returns (uint256) {
        return projects[_id].deadline;
    }

    function getAmount(uint256 _id) public view returns (uint256) {
        return projects[_id].amount;
    }

    function getPaymentToken(uint256 _id) public view returns (address) {
        return projects[_id].paymentToken;
    }

    function getCompleted(uint256 _id) public view returns (bool) {
        return projects[_id].completed;
    }

    function getContribution(uint256 _id, address _funder)
        public
        view
        returns (uint256)
    {
        return contributions[_id][_funder];
    }
}
