require 'rspec'
require './server'

RSpec.describe KeyManager do
    describe "Instance Creation" do
        before :all do
            @keyServer = KeyManager.new
        end
        it "Instance should be created successfully" do
            expect(@keyServer).not_to be_nil
            expect(@keyServer).to be_instance_of(KeyManager)
        end
        it "All variables should be defined and empty by default" do
            expect(@keyServer.allKeys.count).to eq(0)
            expect(@keyServer.availableKeys.count).to eq(0)
            expect(@keyServer.blockedKeys.count).to eq(0)
        end
    end

    describe "Generate Keys" do
        before :all do
            @keyServer = KeyManager.new
            @firstKey = nil
        end
        it "Keys should be added to availableKeys" do
            @keyServer.generateKeys
            expect(@keyServer.availableKeys.count).to eq(KEY_PER_GENERATION)
            @firstKey = @keyServer.availableKeys[0]
        end

        it "should have expiry date" do
            @keyServer.generateKeys
            isExpirySetCorrectly = @keyServer.allKeys.values[0]['expiry'] > Time.now
            expect(isExpirySetCorrectly).to be true 
        end

        it "Keys should be random on each generation" do
            @keyServer.generateKeys
            expect(@keyServer.availableKeys[0]).not_to be == @firstKey
        end
    end

    describe "Get An Available Key" do
        before :all do
            @keyServer = KeyManager.new
        end
        it "should return nil if keys are not generated prior" do
            expect(@keyServer.getAvailableKey).to eq('No Available keys left !')
            expect(@keyServer.availableKeys.count).to eq(0)
        end
        it "should return a key after generateKey is called" do
            @keyServer.generateKeys
            expect(@keyServer.availableKeys.count).to eq(KEY_PER_GENERATION)
            @keyServer.getAvailableKey
            expect(@keyServer.availableKeys.count).to eq(KEY_PER_GENERATION - 1)
            expect(@keyServer.allKeys.count).to eq(KEY_PER_GENERATION)
        end
        it "should return nil if all the keys are assigned" do
            @keyServer.generateKeys
            while @keyServer.blockedKeys.size < KEY_PER_GENERATION + 1 do
                @keyServer.getAvailableKey
            end
            expect(@keyServer.getAvailableKey).to eq("No Available keys left !")
        end
        it "should block the key for one minute" do
            @keyServer.generateKeys
            key = @keyServer.getAvailableKey
            expect(@keyServer.allKeys[key]['blocked_till']).to be < (Time.now + 65)
        end
    end

    describe "Unblock A Key" do
        before :all do
            @keyServer = KeyManager.new
            @keyServer.generateKeys
        end
        it "should unblock the key after assignation" do
            assignedKey = @keyServer.getAvailableKey
            expect(@keyServer.unblockKey(assignedKey)).not_to be_nil
            expect(@keyServer.allKeys[assignedKey]['blocked_till']).to be_nil
        end
        it "should make the key available again" do
            assignedKey = @keyServer.getAvailableKey
            expect(@keyServer.unblockKey(assignedKey)).not_to be_nil
            expect(@keyServer.availableKeys[KEY_PER_GENERATION-1]).to eq(assignedKey)
        end
        it "should not unblock any invalid value" do
            expect(@keyServer.unblockKey('random_key')).to eq('Key is either invalid or not assigned yet !')
        end
    end

    describe "Delete a Key" do
        before :all do
            @keyServer = KeyManager.new
            @keyServer.generateKeys
        end
        it "should delete the key and make it unavailable" do
            key = @keyServer.getAvailableKey
            @keyServer.unblockKey(key)
            expect(@keyServer.deleteKey(key)).not_to be_nil
            expect(@keyServer.blockedKeys.count).to eq(0)
        end
        it "should delete return nil for random keys" do
            expect(@keyServer.deleteKey('random_key')).to eq("Key is either invalid or not assigned yet !")
        end
    end

    describe "Keep Alive endpoint" do
        before :all do
            @keyServer = KeyManager.new
            @keyServer.generateKeys
        end
        it "should increase the expiry time for a key" do
            key = @keyServer.getAvailableKey
            previous_expiry_time = @keyServer.allKeys[key]['expiry']
            @keyServer.keepAliveRefresh(key)
            new_expiry_time = @keyServer.allKeys[key]['expiry']
            is_new_expiry_greater = new_expiry_time > previous_expiry_time
            expect(is_new_expiry_greater).to be true 
        end
    end
end