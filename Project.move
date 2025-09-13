module MyModule::PortfolioTracker {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::vector;
    use std::string::String;

    /// Struct representing a single cryptocurrency holding
    struct Holding has copy, drop, store {
        symbol: vector<u8>,     // Token symbol (e.g., "BTC", "ETH") 
        amount: u64,            // Amount of tokens held
        purchase_price: u64,    // Price paid per token (in APT)
    }

    /// Struct representing a user's crypto portfolio
    struct Portfolio has store, key {
        holdings: vector<Holding>,  // List of cryptocurrency holdings
        total_invested: u64,        // Total amount invested (in APT)
    }

    /// Function to create a new portfolio for a user
    public fun create_portfolio(owner: &signer) {
        let portfolio = Portfolio {
            holdings: vector::empty<Holding>(),
            total_invested: 0,
        };
        move_to(owner, portfolio);
    }

    /// Function to add a new cryptocurrency holding to the portfolio
    public fun add_holding(
        owner: &signer, 
        symbol: vector<u8>, 
        amount: u64, 
        purchase_price: u64
    ) acquires Portfolio {
        let owner_addr = signer::address_of(owner);
        
        // Check if portfolio exists for the owner
        assert!(exists<Portfolio>(owner_addr), 1);
        
        let portfolio = borrow_global_mut<Portfolio>(owner_addr);
        
        // Prevent overflow in investment calculation
        assert!(amount > 0 && purchase_price > 0, 2);
        assert!(amount <= (18446744073709551615u64 / purchase_price), 3); // Prevent overflow
        
        // Create new holding
        let new_holding = Holding {
            symbol,
            amount,
            purchase_price,
        };
        
        // Calculate investment amount
        let investment_amount = amount * purchase_price;
        
        // Register owner for AptosCoin if not already registered
        if (!coin::is_account_registered<AptosCoin>(owner_addr)) {
            coin::register<AptosCoin>(owner);
        };
        
        // Transfer APT from owner (simulating purchase cost)
        let payment = coin::withdraw<AptosCoin>(owner, investment_amount);
        coin::deposit<AptosCoin>(owner_addr, payment);
        
        // Add holding to portfolio
        vector::push_back(&mut portfolio.holdings, new_holding);
        
        // Prevent overflow in total investment
        assert!(portfolio.total_invested <= (18446744073709551615u64 - investment_amount), 4);
        portfolio.total_invested = portfolio.total_invested + investment_amount;
    }
}
