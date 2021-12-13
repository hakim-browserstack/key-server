require 'sinatra'

KEY_PER_GENERATION = 10

#Sample @AvailableKeys Arrays
# [ {key => hber32u432j4, expireAt => 3434234234} ]

# Models
class KeyManager 
    attr_accessor :availableKeys
    attr_accessor :blockedKeys
    attr_accessor :allKeys

    def initialize
        @availableKeys = []
        @blockedKeys = []
        @allKeys = Hash.new
        Thread.new do
            loop do
                sleep 5
                checkExpiry
            end
        end
    end

    def generateKeys
        keyObject = []
        allKeys = @allKeys
        KEY_PER_GENERATION.times do |id|
            key = p SecureRandom.hex(16)
            @allKeys[key] = { 'expiry' => Time.now + (60 * 5) } # Expires after 5 Minutes
            keyObject.push(key)
        end
        @availableKeys = keyObject
        return @availableKeys
    end

    def getAvailableKey
        availableKeysArr = @availableKeys
        if @availableKeys.size > 0 
            availableKey = nil
            @availableKeys.each{ |key|
                 # delete the key always, either its expired or its about to moved to blockedKeys
                idx = availableKeysArr.find_index(key)
                availableKeysArr.delete_at(idx)
                # if not been five mins then provide the available key 
                if Time.now < @allKeys[key]['expiry']
                    availableKey = key
                    @blockedKeys.push(key)
                    #Todo: set an expiry of 1min to it 
                    @allKeys[key]['blocked_till'] = Time.now + 60
                    break
                end
            }
            @availableKeys = availableKeysArr
            return availableKey
        else 
            'No Available keys left !'
        end
    end

    def unblockKey(keyToUnblock)
        idx = @blockedKeys.find_index(keyToUnblock)
        if idx != nil
            @blockedKeys.delete_at(idx)
            @availableKeys.push(keyToUnblock)
            allKeys[keyToUnblock] =  {'expiry' => Time.now + (60 * 5)}
            'unblocked => ' + keyToUnblock
        else 
            'Key is either invalid or not assigned yet !'
        end
    end

    def deleteKey(keyToDelete)
        # This will only delete an already assigned key 
        idx = @blockedKeys.find_index(keyToDelete)
        if idx != nil
            @blockedKeys.delete_at(idx)
            @allKeys.delete(keyToDelete)
            'deleted => ' + keyToDelete
        else 
            'Key is either invalid or not assigned yet !' 
        end
    end

    def keepAliveRefresh(keyToRefresh)
        # if the key has not already expired then update the expiry to 5mins
        if @allKeys[keyToRefresh]['expiry'] > Time.now
            @allKeys[keyToRefresh]['expiry'] = Time.now + (60 * 5)
        # if its expired then delete the key altogether
        else
            self.deleteKey(keyToRefresh)
            'The key is either invalid or expired'
        end

    end

    def checkExpiry
        current_time = Time.now
        @allKeys.each {|key, value|
            unblockKey(key) if value['blocked_till'] && (value['blocked_till'] < current_time)
            deleteKey(key) if value['expiry'] < current_time
        }
    end

    # # # # # # # # # # # 
    # # FOR DEBUGGING # # 
    # # # # # # # # # # # 

    def getStats
        stats = {
            'availableKeys' => @availableKeys,
            'blockedKeys' => @blockedKeys,
            'allKeys' => @allKeys
        }
        stats
    end
end  

myKeyManager = KeyManager.new

get '/' do
    'Welcome to Key Server!'
end

get '/generate_keys' do
    myKeyManager.generateKeys.inspect
end

get '/get_available_key' do
    myKeyManager.getAvailableKey
end

get '/unblock_key' do
    keyToUnblock = params['key']
    myKeyManager.unblockKey(keyToUnblock)
end

get '/delete_key' do
    keyToDelete = params['key']
    myKeyManager.deleteKey(keyToDelete)
end

get '/keep_alive_refresh' do
    keyToRefresh = params['key']
    myKeyManager.keepAliveRefresh(keyToRefresh)
end

# # # # # # # # # # # 
# # FOR DEBUGGING # # 
# # # # # # # # # # # 

get '/get_stats' do
    myKeyManager.getStats.inspect
end