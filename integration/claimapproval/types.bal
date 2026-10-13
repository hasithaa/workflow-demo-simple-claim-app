
type Claim record {|
    string employee;
    string description;
    decimal amount;
|};

type Bill record {|
    string fileName;
    string fileUrl;
|};

# Data record for workflow function
type ProcessClaimData record {|
    future<Bill> bill;
|};

type Decision record {|
    boolean approved;
    string comment;
|};
