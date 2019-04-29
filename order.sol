pragma solidity >=0.4.22 <0.6.0;

contract service {

    struct ServiceOrder {
        uint serviceId;
        string serviceName;
        address payable provider;  
        address payable customer;  
        uint price;
        orderStatus status;
    }

    enum orderStatus{ Created, InProgress, Closed }
    
    ServiceOrder serviceOrder;
    
    mapping (address => uint) public pendingWithdrawals;

    event amountRecieved(address provider,uint serviceId);
    event serviceOrderCreated( address provider, string serviceName, uint serviceId, uint price);
    event serviceOrderClosed(address provider, uint serviceId);
    event withdrawDone(address person, uint amount);
    
    function createServiceOrder (uint serviceId, string calldata serviceName, address payable provider, 
        address payable customer, uint price) external {
        require(bytes(serviceName).length != 0 && price != 0);
        serviceOrder = ServiceOrder({
            serviceId: serviceId,
            serviceName: serviceName, 
            provider: provider, 
            customer: customer,
            price: price,
            status: orderStatus.Created
        });
        emit serviceOrderCreated(provider, serviceName, serviceId, price);
    }

    function requestService (address provider) external payable {
        ServiceOrder storage a = serviceOrder;
        require(msg.value == a.price && a.status == orderStatus.Created);
        a.status = orderStatus.InProgress;
        emit amountRecieved(provider, a.serviceId);
    }

    function closeServiceOrder(address provider, uint serviceId) external returns (bool) {
        ServiceOrder storage a = serviceOrder;
        require(msg.sender == a.provider && a.status == orderStatus.InProgress);
        a.status = orderStatus.Closed;
        pendingWithdrawals[a.provider] += a.price;
        withdraw(a.provider);
        emit serviceOrderClosed(provider, serviceId);
        return true;
    }

     function withdraw(address payable person) private {
        uint amount = pendingWithdrawals[person];
        pendingWithdrawals[person] = 0;
        person.transfer(amount);
        emit withdrawDone(person, amount);
    }
    
}
