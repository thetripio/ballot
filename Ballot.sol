pragma solidity ^0.4.24;
import "./extensions/LinkedListLib.sol";
import "./extensions/Owned.sol";
import "./extensions/SafeMath.sol";

contract Ballot is Owned {
    using LinkedListLib for LinkedListLib.LinkedList;
    using SafeMath for uint256;
    
    constructor () public {
        
    }
    
    uint256 public totalSupply;
    string public name = "Ecotech Ballot Token";
    string public symbol = "STAR";
    uint8 public decimals = 0;

    // 候选人
    struct Voter {
        uint256 vote;
        uint256 balance;
        address ads;
        bytes32 name;
    }

    mapping (uint256 => Voter) voters;
    mapping (address => uint256) voterIds;
    LinkedListLib.LinkedList voterList = LinkedListLib.LinkedList(0, 0);

    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev 添加投票人
     * @param _voterIds 投票人地址
     * @param _voterNames 投票人姓名(转为bytes32)
     */
    function addVoters(address[] _voterIds, bytes32[] _voterNames) external onlyOwner {
        uint256 id = 0;
        require(_voterIds.length == _voterNames.length && _voterNames.length > 0);
        for (uint256 i = 0;i < _voterIds.length; i++) {
            id = voterList.push(false);
            voters[id] = Voter(0, 0, _voterIds[i], _voterNames[i]);
            voterIds[_voterIds[i]] = id;
        }
    }

    /**
     * @dev 删除投票人
     * @param _voterIds 投票人IDs
     */
    function removeVoters(uint256[] _voterIds) external onlyOwner {
        require(_voterIds.length > 0);
        uint256 vid = 0;
        for (uint256 i = 0;i < _voterIds.length; i++) {
            vid = _voterIds[i];
            require(voterList.nodeExists(vid));
            totalSupply = totalSupply.sub(voters[vid].balance);
            delete voterIds[voters[vid].ads];
            delete voters[vid];
            voterList.remove(vid);
        }
    }

    /**
     * @dev 清空所有人手里的票
     */
    function burnVotes() external onlyOwner {
        uint256[] memory _vids;
        uint256 _next;
        (_vids, _next) = voterList.getNodes(0, voterList.sizeOf(), true);
        for (uint256 i = 0;i < _vids.length; i++) {
            voters[_vids[i]].vote = 0;
        }
    }

    /**
     * @dev 清空投票结果
     */
    function burnBalances() external onlyOwner {
        uint256[] memory _vids;
        uint256 _next;
        (_vids, _next) = voterList.getNodes(0, voterList.sizeOf(), true);
        for (uint256 i = 0;i < _vids.length; i++) {
            voters[_vids[i]].balance = 0;
        }
        totalSupply = 0;
    }

    /**
     * @dev 给所有人发放相同的票数
     * @param _vote 票数
     */
    function addVotes(uint256 _vote) external onlyOwner {
        uint256[] memory _vids;
        uint256 _next;
        (_vids, _next) = voterList.getNodes(0, voterList.sizeOf(), true);
        for (uint256 i = 0;i < _vids.length; i++) {
            voters[_vids[i]].vote = voters[_vids[i]].vote.add(_vote);
        }
    }

    /**
     * @dev 给某人发放票数
     * @param _vote 票数
     * @param _to 目标人地址
     */
    function addVote(uint256 _vote, address _to) external onlyOwner{
        uint256 vid = voterIds[_to];
        require(voterList.nodeExists(vid));
        voters[vid].vote = voters[vid].vote.add(_vote);
    }

    /**
     * @dev 查询所有的候选人IDs
     * @param _from 开始ID，如果从头开始_from=0
     * @param _limit 每页显示数量
     * @return 返回所有的IDs和下一个ID，如果下一个ID=0说明已经没有下一页
     */
    function getVoters(uint256 _from, uint256 _limit) external view returns(uint256[], uint256) {
        return voterList.getNodes(_from, _limit, true);
    }

    /**
     * @dev 获取候选人详情
     * @param _vid 候选人ID
     * @return 返回持有票数、被投票数、地址、姓名
     */
    function getVoter(uint256 _vid) external view returns(uint256,uint256, address, bytes32) {
        return (voters[_vid].vote,voters[_vid].balance, voters[_vid].ads, voters[_vid].name);
    }

    /**
     * @dev 查询自己的信息
     * @return 返回持有票数、被投票数、地址、姓名
     */
    function getOneself() external view returns(uint256,uint256, address, bytes32) {
        uint256 vid = voterIds[msg.sender];
        return (voters[vid].vote,voters[vid].balance, voters[vid].ads, voters[vid].name);
    }
    
    /**
     * @dev 查询某人的被投票情况
     * @param _tokenOwner 地址
     * @return 返回被查询者的被投票情况
     */
    function balanceOf(address _tokenOwner) public view returns (uint balance) {
        uint256 vid = voterIds[_tokenOwner];
        return voters[vid].balance;
    }
    
    /**
     * @dev 投票，不能投给自己；投票人和候选人都要在列表中
     * @param _to 被选人
     * @param _tokens 票数
     */
    function transfer(address _to, uint _tokens) public returns (bool success) {
        // 不能投给自己
        require(_to != msg.sender);
        
        // 投票人在候选人列表
        uint256 vid = voterIds[msg.sender];
        require(voterList.nodeExists(vid));
        voters[vid].vote = voters[vid].vote.sub(_tokens);

        // 被投票人也在候选人列表
        uint256 toVid = voterIds[_to];
        require(voterList.nodeExists(toVid));
        voters[toVid].balance = voters[toVid].balance.add(_tokens);
        
        // 记录所有投出的票数
        totalSupply = totalSupply.add(_tokens);
        emit Transfer(msg.sender, _to, _tokens);
        return true;
    }
}