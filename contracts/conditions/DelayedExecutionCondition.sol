pragma solidity 0.4.17;
import "../Condition.sol";
import "../GnosisSafe.sol";


/// @title Delayed Execution Condition - Requires to wait a defined period before a transaciton can be executed.
/// @author Stefan George - <stefan@gnosis.pm>
contract DelayedExecutionCondition is Condition {

    event DelayChange(uint delay);
    event TransactionSubmission(bytes32 transactionHash);

    string public constant NAME = "Delayed Execution Condition";
    string public constant VERSION = "0.0.1";

    GnosisSafe public gnosisSafe;
    uint public delay;
    mapping (bytes32 => uint) public submissionTimes;

    modifier onlyGnosisSafe() {
        require(msg.sender == address(gnosisSafe));
        _;
    }

    function DelayedExecutionCondition(uint _delay)
        public
    {
        gnosisSafe = GnosisSafe(msg.sender);
        delay = _delay;
        DelayChange(_delay);
    }

    function changeDelay(uint _delay)
        public
        onlyGnosisSafe
    {
        delay = _delay;
        DelayChange(_delay);
    }

    function submitTransaction(bytes32 transactionHash)
        public
    {
        require(gnosisSafe.isConfirmedByRequiredOwners(transactionHash));
        submissionTimes[transactionHash] = now;
        TransactionSubmission(transactionHash);
    }

    function isExecutable(address sender, address to, uint value, bytes data, GnosisSafe.Operation operation, uint nonce)
        public
        returns (bool)
    {
        bytes32 transactionHash = gnosisSafe.getTransactionHash(to, value, data, operation, nonce);
        if (   submissionTimes[transactionHash] > 0
            && now - submissionTimes[transactionHash] > delay)
            return true;
        return false;
    }
}
