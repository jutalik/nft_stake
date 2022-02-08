pragma solidity ^0.5.6;

contract NFTCONTRACT {
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256 tokenId);

    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool);

    function ownerOf(uint256 tokenId) public view returns (address);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public;
}

contract DBCONTRACT {
    // function viewPower(string memory _addr_tokenId) external view returns(string memory,uint);
    function viewPower(string memory _addr_tokenId)
        public
        view
        returns (string memory, uint256);
}

contract TOKENCONTRACT {
    function transfer(address _to, uint256 _value)
        public
        returns (bool success);

    // function _transfer(address _from, address _to, uint _value) external;
    function balanceOf(address tokenOwner)
        public
        view
        returns (uint256 balance);
}

contract StakingCore {
    uint256 public totalKlay = 0; //전체 보상되어야 하는 클레이
    uint256 public totalPER = 0; //전체 보상되어야 하는 PER
    uint256 public sblock; //contract 배포시작 block
    uint256 public totalMining = 0; //Staking되어 있는 총 채굴력
    uint256 public maxSlot = 5;
    uint256 public percentagePER = 1; //전체 풀에서 시간단위 별 보상이 지급되어야 하는 PER %
    uint256 public percentageKLAY = 1; //전체 풀에서 시간단위 별 보상이 지급되어야 하는 KLAY %
    uint256 public blockCount = 3600; //보상을 지급할 block구간
    uint256 public decimal = 1000000;

    struct Staker {
        uint256 miningPower; // Staker가 소유한 nft의 power
        uint256 insertBlockNum; //deposit한 시점의 block number
        uint256 tokenID; //소유한 nft ID
    }

    mapping(address => mapping(uint256 => Staker)) public stakersDatas; //스테이킹 진행하고 있는 사람들 데이터
    mapping(uint256 => uint256) public PERPerBlock; //block number에 따라 1 mining power당 지급되어야 하는 per 양
    mapping(uint256 => uint256) public KLAYPerBlock; //block number에 따라 1 mining power당 지급되어야 하는 per 양
    mapping(address => uint256) public depositCount; //user Deposit 개수
    mapping(address => uint256[]) public depositCards; //user Depoist한 카드 ID

    constructor() public {
        sblock = block.number;
    }

    function updateTotalPer(uint256 _totalPer) internal {
        totalPER = _totalPer;
    }

    function insertPERPerBlock(uint256 _blockNum, uint256 _value) internal {
        PERPerBlock[_blockNum] = _value;
    }

    function calculatePerBlock(uint256 _decimal, uint256 _percentagePER)
        internal
        view
        returns (uint256)
    {
        if (totalMining <= 0 || totalPER <= 0) {
            return 0;
        } else {
            uint256 _perPER = div(totalPER, totalMining);
            uint256 _applyPercent = mul(_perPER, _percentagePER);
            if (_applyPercent >= _decimal) {
                return div(_applyPercent, _decimal);
            } else {
                return 0;
            }
        }
    }

    function EXcalculatePerBlock(uint256 _decimal, uint256 _percentagePER)
        external
        view
        returns (uint256)
    {
        if (totalMining <= 0 || totalPER <= 0) {
            return 0;
        } else {
            uint256 _perPER = div(totalPER, totalMining);
            uint256 _applyPercent = mul(_perPER, _percentagePER);
            if (_applyPercent >= _decimal) {
                return div(_applyPercent, _decimal);
            } else {
                return 0;
            }
        }
    }

    function updateTotalKlay(uint256 _totalKlay) internal {
        totalKlay = _totalKlay;
    }

    function insertKlayPerBlock(uint256 _blockNum, uint256 _value) internal {
        KLAYPerBlock[_blockNum] = _value;
    }

    function calculateKlayBlock(uint256 _decimal, uint256 _percentageKLAY)
        internal
        view
        returns (uint256)
    {
        if (totalMining <= 0 || totalKlay <= 0) {
            return 0;
        } else {
            uint256 _perKlay = div(totalKlay, totalMining);
            uint256 _applyPercent = mul(_perKlay, _percentageKLAY);
            if (_applyPercent >= _decimal) {
                return div(_applyPercent, _decimal);
            } else {
                return 0;
            }
        }
    }

    function EXcalculateKlayBlock(uint256 _decimal, uint256 _percentageKLAY)
        external
        view
        returns (uint256)
    {
        if (totalMining <= 0 || totalKlay <= 0) {
            return 0;
        } else {
            uint256 _perKlay = div(totalKlay, totalMining);
            uint256 _applyPercent = mul(_perKlay, _percentageKLAY);
            if (_applyPercent >= _decimal) {
                return div(_applyPercent, _decimal);
            } else {
                return 0;
            }
        }
    }

    function increaseMiningPower(uint256 _MiningValue) internal {
        // 현재 klay 가격과 update되는 value의 합이 0보다 클때만 해당
        require(totalMining + _MiningValue > 0);
        totalMining += _MiningValue;
    }

    function decreaseMiningPower(uint256 _MiningValue) internal {
        require(totalMining - _MiningValue >= 0);
        totalMining -= _MiningValue;
    }

    function getStakerData(address _user, uint256 _tokenID)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        Staker memory _staker = stakersDatas[_user][_tokenID];
        return (_staker.miningPower, _staker.insertBlockNum, _staker.tokenID);
    }

    function setDecimal(uint256 _decimal) external {
        require(_decimal % 10 == 0);
        decimal = _decimal;
    }

    function setBlockCount(uint256 _blockCount) external {
        require(_blockCount > 0);
        blockCount = _blockCount;
    }

    // 시간당 예치풀에서 지급하는 per 지급량 설정 1000000 = 100%
    function setPercentagePer(uint256 _percentagePER) external {
        require(_percentagePER >= 0 || _percentagePER <= decimal);
        percentagePER = _percentagePER;
    }

    // 시간당 예치풀에서 지급하는 klay 지급량 설정 1000000 = 100%
    function setPercentageKlay(uint256 _percentageKLAY) external {
        require(_percentageKLAY >= 0 || _percentageKLAY <= decimal);
        percentageKLAY = _percentageKLAY;
    }

    function deposit(
        address _user,
        uint256 _tokenId,
        uint256 _cardPower,
        uint256 _totalKlay,
        uint256 _totalPER
    ) external {
        require(depositCount[_user] <= maxSlot);
        stakersDatas[_user][_tokenId] = Staker(
            _cardPower,
            block.number,
            _tokenId
        ); //새로운 staker 등록
        increaseMiningPower(_cardPower);
        updateTotalKlay(_totalKlay);
        updateTotalPer(_totalPER);
        uint256 _klayBlock = calculateKlayBlock(decimal, percentageKLAY);
        uint256 _perBlock = calculatePerBlock(decimal, percentagePER);
        insertKlayPerBlock(block.number, _klayBlock);
        insertPERPerBlock(block.number, _perBlock);
        depositCount[_user] = depositCount[_user] + 1; //민팅시 slot 하나 채워짐
        depositCards[_user].push(_tokenId);
    }

    function withdraw(
        address _user,
        uint256 _tokenID,
        uint256 _miningPower,
        uint256 _totalKlay,
        uint256 _totalPER
    ) external {
        delete stakersDatas[_user][_tokenID];
        updateTotalKlay(_totalKlay);
        updateTotalPer(_totalPER);
        decreaseMiningPower(_miningPower);
        uint256 _klayBlock = calculateKlayBlock(decimal, percentageKLAY);
        uint256 _perBlock = calculatePerBlock(decimal, percentagePER);
        insertKlayPerBlock(block.number, _klayBlock);
        insertPERPerBlock(block.number, _perBlock);
        depositCount[_user] = depositCount[_user] - 1; //count 삭제
        deleteDepositCards(_tokenID, _user);
    }

    function collect(
        address _user,
        uint256 _tokenID,
        uint256 _totalKlay,
        uint256 _totalPER
    ) external {
        updateTotalKlay(_totalKlay);
        updateTotalPer(_totalPER);
        uint256 _klayBlock = calculateKlayBlock(decimal, percentageKLAY);
        uint256 _perBlock = calculatePerBlock(decimal, percentagePER);
        insertKlayPerBlock(block.number, _klayBlock);
        insertPERPerBlock(block.number, _perBlock);
        if (
            block.number - stakersDatas[_user][_tokenID].insertBlockNum >=
            blockCount
        ) {
            stakersDatas[_user][_tokenID].insertBlockNum = block.number;
        }
    }

    function getRewardKlay(uint256 _tokenID, address _user)
        external
        view
        returns (uint256)
    {
        uint256 _nowblock = block.number;
        Staker memory _staker = stakersDatas[_user][_tokenID];
        require(_staker.insertBlockNum > 0);
        uint256 _gap = 0;
        uint256 _time = 0;
        if (_nowblock - _staker.insertBlockNum > 0) {
            _gap = _nowblock - _staker.insertBlockNum;
            _gap = _gap - (_gap % blockCount);
            _time = div(_gap, blockCount);
        }
        uint256 _lastValue = KLAYPerBlock[_staker.insertBlockNum];
        uint256 _sum = 0;
        for (
            uint256 i = _staker.insertBlockNum;
            i < _staker.insertBlockNum + _gap;
            i++
        ) {
            if (KLAYPerBlock[i] > 0 && _lastValue != KLAYPerBlock[i]) {
                _lastValue = KLAYPerBlock[i];
            }
            _sum = _sum + _lastValue;
        }
        uint256 _avg = div(_sum, _gap);
        uint256 _avgReward = mul(_avg, _staker.miningPower);
        return mul(_avgReward, _time);
    }

    function getRewardPER(uint256 _tokenID, address _user)
        external
        view
        returns (uint256)
    {
        uint256 _nowblock = block.number;
        Staker memory _staker = stakersDatas[_user][_tokenID];
        uint256 _gap = 0;
        uint256 _time = 0;
        if (_nowblock - _staker.insertBlockNum > 0) {
            _gap = _nowblock - _staker.insertBlockNum;
            _gap = _gap - (_gap % blockCount);
            _time = div(_gap, blockCount);
        }

        uint256 _lastValue = PERPerBlock[_staker.insertBlockNum];
        uint256 _sum = 0;
        for (
            uint256 i = _staker.insertBlockNum;
            i < _staker.insertBlockNum + _gap;
            i++
        ) {
            if (_lastValue != PERPerBlock[i] && PERPerBlock[i] > 0) {
                _lastValue = PERPerBlock[i];
            }
            _sum = _sum + _lastValue;
        }

        uint256 _avg = div(_sum, _gap);
        uint256 _avgReward = mul(_avg, _staker.miningPower);
        return mul(_avgReward, _time);
    }

    function getRewardPER_Test(uint256 _tokenID, address _user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 _nowblock = block.number;
        Staker memory _staker = stakersDatas[_user][_tokenID];
        uint256 _gap = 0;
        uint256 _time = 0;
        if (_nowblock - _staker.insertBlockNum > 0) {
            _gap = _nowblock - _staker.insertBlockNum;
            _gap = _gap - (_gap % blockCount);
            _time = div(_gap, blockCount);
        }

        uint256 _lastValue = PERPerBlock[_staker.insertBlockNum];
        uint256 _sum = 0;
        for (
            uint256 i = _staker.insertBlockNum;
            i < _staker.insertBlockNum + _gap;
            i++
        ) {
            if (_lastValue != PERPerBlock[i] && PERPerBlock[i] > 0) {
                _lastValue = PERPerBlock[i];
            }
            _sum = _sum + _lastValue;
        }

        uint256 _avg = div(_sum, _gap);
        uint256 _avgReward = mul(_avg, _staker.miningPower);
        return (
            _nowblock,
            _staker.insertBlockNum,
            _gap,
            _time,
            _sum,
            _avg,
            _avgReward
        );
    }

    function getDepositCards(address _user)
        external
        view
        returns (uint256[] memory)
    {
        return depositCards[_user];
    }

    function deleteDepositCards(uint256 _tokenID, address _user) internal {
        uint256 _deleteIndex;
        for (uint256 i = 0; i < depositCards[_user].length; i++) {
            if (depositCards[_user][i] == _tokenID) {
                _deleteIndex = i;
            }
        }
        depositCards[_user][_deleteIndex] = depositCards[_user][
            depositCards[_user].length - 1
        ];
        depositCards[_user].length--;
    }

    //uint division
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b || a <= 0) return 0;
        return a / b;
    }

    //uint multipl
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= 0 || b <= 0) return 0;
        if (a * b < 0) return 0;
        return a * b;
    }
}

contract StakingFunction {
    StakingCore core;
    DBCONTRACT dbContract;
    NFTCONTRACT nftContract;
    TOKENCONTRACT tokenContract;

    constructor(address _core) public {
        dbContract = DBCONTRACT(0xaE2C57a0f93398A08E4ea5f922A8465146Be2dd8);
        nftContract = NFTCONTRACT(0xd6DC0CBf526eB868F357854404943187EAAdEa29);
        tokenContract = TOKENCONTRACT(
            0x002214b36a80d6981a7dcdabe7e5e6aa7a2fcbcc83
        );
        core = StakingCore(_core);
    }

    //============================= admin 동작 관련 함수들 ===================================

    function setNFTContract(address _nft) external {
        nftContract = NFTCONTRACT(_nft);
    }

    function setDBContract(address _dbContractAddress) external {
        dbContract = DBCONTRACT(_dbContractAddress);
    }

    function setCoreContract(address _coreContractAddress) external {
        core = StakingCore(_coreContractAddress);
    }

    function nftReturn(uint256 _tokenID) external {
        nftContract.transferFrom(address(this), msg.sender, _tokenID);
    }

    //=====================================================================================

    function deposit(uint256 _tokenId) external {
        string memory checkPowerString = append(
            "0x0Ed55aEe0399064Cfe51dD3cC10D99734bb796c78472",
            uint2str(_tokenId)
        );
        (, uint256 cardPower) = dbContract.viewPower(checkPowerString); //card power 가져오기
        require(cardPower > 0, "card power not find"); //card power가 존재하는 경우만 실행
        require(nftContract.ownerOf(_tokenId) == msg.sender, "not your card"); //해당 토큰의 소유자 확인
        require(
            nftContract.isApprovedForAll(msg.sender, address(this)) == true,
            "not approve All"
        ); //approve 허용이 안된 경우 반려
        nftContract.transferFrom(msg.sender, address(this), _tokenId); //nft를 해당 contract로 소유권 이전

        uint256 _totalKlay = address(this).balance;
        uint256 _totalPER = tokenContract.balanceOf(address(this));
        core.deposit(msg.sender, _tokenId, cardPower, _totalKlay, _totalPER);
    }

    function witdraw(uint256 _tokenID) public {
        (uint256 miningPower, , uint256 tokenID) = core.getStakerData(
            msg.sender,
            _tokenID
        );
        uint256 _avgValueKlay = core.getRewardKlay(tokenID, msg.sender);
        uint256 _avgValuePer = core.getRewardPER(tokenID, msg.sender);

        nftContract.transferFrom(address(this), msg.sender, tokenID); //nft 돌려주기

        if (_avgValueKlay > 0) {
            msg.sender.transfer(_avgValueKlay); //계산된 klay 전송
        }

        if (_avgValuePer > 0) {
            tokenContract.transfer(msg.sender, _avgValuePer); //계산된 per 전송
        }

        uint256 _totalKlay = address(this).balance;
        uint256 _totalPER = tokenContract.balanceOf(address(this));
        core.withdraw(msg.sender, _tokenID, miningPower, _totalKlay, _totalPER);
    }

    function witdraws(uint256[] calldata _tokenIDs) external {
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            witdraw(_tokenIDs[i]);
        }
    }

    function collection(uint256 _tokenID) public {
        (, , uint256 tokenID) = core.getStakerData(msg.sender, _tokenID);
        uint256 _avgValueKlay = core.getRewardKlay(tokenID, msg.sender);
        uint256 _avgValuePer = core.getRewardPER(tokenID, msg.sender);
        if (_avgValueKlay > 0) {
            msg.sender.transfer(_avgValueKlay); //계산된 klay 전송
        }

        if (_avgValuePer > 0) {
            tokenContract.transfer(msg.sender, _avgValuePer); //계산된 per 전송
        }
        uint256 _totalKlay = address(this).balance;
        uint256 _totalPER = tokenContract.balanceOf(address(this));
        core.collect(msg.sender, _tokenID, _totalKlay, _totalPER);
    }

    function collections(uint256[] calldata _tokenIDs) external {
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            collection(_tokenIDs[i]);
        }
    }

    //uint 를 string 변환 함수
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    //string
    function append(string memory a, string memory b)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }
}
