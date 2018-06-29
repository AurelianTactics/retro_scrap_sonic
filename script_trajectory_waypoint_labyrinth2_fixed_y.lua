level_max_x = {
-- Green Hill Zone
    ["zone=0,act=0"] = 0x2560,
    ["zone=0,act=1"] = 0x1F60,
    ["zone=0,act=2"] = 0x292A,

-- Marble Zone
    ["zone=2,act=0"] = 0x1860,
    ["zone=2,act=1"] = 0x1860,
    ["zone=2,act=2"] = 0x1720,

-- Spring Yard Zone
    ["zone=4,act=0"] = 0x2360,
    ["zone=4,act=1"] = 0x2960,
    ["zone=4,act=2"] = 0x2B83,

-- Labyrinth Zone
    ["zone=1,act=0"] = 0x1A50,
    ["zone=1,act=1"] = 0x1150,
    ["zone=1,act=2"] = 0x1CC4,

-- Star Light Zone
    ["zone=3,act=0"] = 0x2060,
    ["zone=3,act=1"] = 0x2060,
    ["zone=3,act=2"] = 0x1F48,

-- Scrap Brain Zone
    ["zone=5,act=0"] = 0x2260,
    ["zone=5,act=1"] = 0x1EE0,
    -- ["zone=5,act=2"] = 000000, -- does not have a max x
}

function clip(v, min, max)
    if v < min then
        return min
    elseif v > max then
        return max
    else
        return v
    end
end

prev_lives = 3

function contest_done()
    if data.lives < prev_lives then
        return true
    end
    prev_lives = data.lives

    if calc_progress(data) >= 1 then
        return true
    end

    return false
end

offset_x = nil
end_x = nil
prev_x = nil --added these for waypoint check
prev_y = nil

function calc_progress(data)
    if offset_x == nil then
        offset_x = -data.x
        local key = string.format("zone=%d,act=%d", data.zone, data.act)
        end_x = level_max_x[key] - data.x
	prev_x = data.x
	prev_y = data.y
    end

    local cur_x = clip(data.x + offset_x, 0, end_x)
    return cur_x / end_x
end

prev_progress = 0
frame_count = 0
frame_limit = 18000

function contest_reward()
    frame_count = frame_count + 1
    local progress = calc_progress(data)
    local reward = (progress - prev_progress) * 9000
    prev_progress = progress

    -- bonus for beating level quickly
    if progress >= 1 then
        reward = reward + (1 - clip(frame_count/frame_limit, 0, 1)) * 1000
    end
    return reward
end


function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end


tolerance_check = 0 --sets how close to human trajectory needs to be
-- calc progress along a trajectory
function calc_trajectory_progress(data)
    
    local ret_value = check_progress_dict(data.x,data.y)
    if ret_value ~= nil then
	return ret_value
    end
 
    if tolerance_check > 1 then
	local z1 = 1
	while (z1 < tolerance_check) do
	    ret_value = check_progress_dict(data.x,data.y-z1)
	    if ret_value ~= nil then
	        break
	    end
	    ret_value = check_progress_dict(data.x,data.y+z1)
	    if ret_value ~= nil then
	        break
	    end
	    ret_value = check_progress_dict(data.x-z1,data.y)
	    if ret_value ~= nil then
	        break
	    end
	    ret_value = check_progress_dict(data.x+z1,data.y)
	    if ret_value ~= nil then
	        break
	    end
	    ret_value = check_progress_dict(data.x-z1,data.y+z1)
	    if ret_value ~= nil then
	        break
	    end
	    ret_value = check_progress_dict(data.x+z1,data.y-z1)
	    if ret_value ~= nil then
	        break
	    end
	    ret_value = check_progress_dict(data.x-z1,data.y-z1)
	    if ret_value ~= nil then
	        break
	    end
	    ret_value = check_progress_dict(data.x+z1,data.y+z1)
	    if ret_value ~= nil then
	        break
	    end
	    z1 = z1 + 1
	end
    end
    return ret_value  
end

function check_progress_dict(x,y)
    local key = tostring(x) .. "," .. tostring(y)
    if level_progress_dict[key] ~= nil then
	return tonumber(level_progress_dict[key])
    end
    return nil
end

prev_step = 0

-- reward as compared to user trajectory
function reward_by_trajectory()
    frame_count = frame_count + 1
    local level_done = calc_progress(data)
    local temp_progress = calc_trajectory_progress(data)
    
    local reward = 0
    if temp_progress ~= nil then
	reward = (temp_progress/level_dict_len - prev_step/level_dict_len) * 9000
	reward = clip(reward,-400.1,400.1)	
	prev_step = temp_progress
    end

    if level_done >= 1 then
	reward = reward + (1 - clip(frame_count/frame_limit, 0, 1)) * 1000
    end

    return reward
end


prev_step_max = 0

-- reward that allows backtracking, only rewarded by getting max trajectory
function reward_by_max_trajectory()
    frame_count = frame_count + 1
    local level_done = calc_progress(data)
    local temp_progress = calc_trajectory_progress(data)

    local reward = reward_by_ring(data)
    if (temp_progress ~= nil and temp_progress > prev_step_max) then
	reward = (temp_progress/level_dict_len - prev_step_max/level_dict_len) * 9000
	reward = clip(reward,-400.1,400.1)
	prev_step_max = temp_progress
    end

    if level_done >= 1 then
	reward = reward + (1 - clip(frame_count/frame_limit, 0, 1)) * 1000
    end

    return reward
end


prev_ring_num = 0
function reward_by_ring(data)
    local ring_reward = 0
    local current_ring_num = data.rings
    if current_ring_num < prev_ring_num then
	ring_reward = -10.0
    elseif current_ring_num > prev_ring_num then
	if prev_ring_num == 0 then
	    ring_reward = 2.0
	else
	    ring_reward = 0.1
	end
    end

    prev_ring_num = current_ring_num
    return ring_reward
end

waypoint_length = 12
function get_waypoint_x_dict()
    local ret_x = {}
    ret_x[0] = 762
    ret_x[1] = 309
    ret_x[2] = 1931
    ret_x[3] = 2007
    ret_x[4] = 2092
    ret_x[5] = 2224
    ret_x[6] = 2544
    ret_x[7] = 2598
    ret_x[8] = 2069
    ret_x[9] = 2989
    ret_x[10] = 3602
    ret_x[11] = 4467

    return ret_x
end

function get_waypoint_y_dict()
    local ret_y = {}
    ret_y[0] = 1004
    ret_y[1] = 1132
    ret_y[2] = 1260
    ret_y[3] = 647
    ret_y[4] = 492
    ret_y[5] = 556
    ret_y[6] = 492
    ret_y[7] = 1516
    ret_y[8] = 1612
    ret_y[9] = 1516
    ret_y[10] = 876
    ret_y[11] = 1004
    return ret_y
end

waypoint_x_dict = get_waypoint_x_dict()
waypoint_y_dict = get_waypoint_y_dict()

--reward scaled by total distance travelled
--want total distance for level to be scaled with the 9k reward
--called once after prev_x and prev_y are initialized
function get_total_distance(x,y)
    local distance = math.sqrt((x-waypoint_x_dict[0])^2 + (y-waypoint_y_dict[0])^2)
    for i = 0, waypoint_length-2 do
    	distance = distance + math.sqrt((waypoint_x_dict[i]-waypoint_x_dict[i+1])^2 + (waypoint_y_dict[i]-waypoint_y_dict[i+1])^2)
    end
    return distance
end

--checks to see if waypoint reached. if so gives reward and sets waypoint to next waypoint
prev_distance = nil
current_waypoint = 0
waypoint_x = waypoint_x_dict[current_waypoint]
waypoint_y = waypoint_y_dict[current_waypoint]
waypoint_minibonus = 100/waypoint_length
function calc_waypoint(data)
    if data.x == waypoint_x and data.y == waypoint_y then
	prev_distance = nil
	current_waypoint = current_waypoint + 1
	if current_waypoint < waypoint_length then
	    waypoint_x = waypoint_x_dict[current_waypoint]
	    waypoint_y = waypoint_y_dict[current_waypoint]
	end
	--reward bonus for reaching waypoint
	return (1 - clip(frame_count/frame_limit, 0, 1)) * waypoint_minibonus
    end

    return 0
end


--get reward for getting closer to waypoint, less for further from waypoint
waypoint_reward_scale = nil
prev_screen_y = nil
function reward_by_waypoint()
    frame_count = frame_count + 1
    local level_done = calc_progress(data)

    --local reward = reward_by_ring(data)
    local reward = 0
    reward = calc_waypoint(data)

    if prev_distance == nil then
	prev_distance = math.sqrt((prev_x-waypoint_x)^2 + (prev_y-waypoint_y)^2)
    end

    if waypoint_reward_scale == nil then
	local total_distance = get_total_distance(prev_x,prev_y)
	waypoint_reward_scale = 9000.0/total_distance
	prev_screen_y = data.screen_y
    end

    --deaths aren't registed right away but sonic will move a lot on the y axis
	--this is a rough check for that
    if (data.x ~= prev_x) or (data.screen_y ~= prev_screen_y) or math.abs((data.y-prev_y)) < 6 then
	local curr_distance = math.sqrt((data.x-waypoint_x)^2 + (data.y-waypoint_y)^2)
	local distance_reward = (prev_distance - curr_distance)*waypoint_reward_scale
	reward = reward + distance_reward
    end

    
    prev_distance = curr_distance
    prev_x = data.x
    prev_y = data.y
    prev_screen_y = data.screen_y

    if level_done >= 1 then
	reward = reward + (1 - clip(frame_count/frame_limit, 0, 1)) * 1000
    end

    return reward
end


-- load level dictionary and see how long it is
--[=====[ 
level_dict_len = 8868

function get_level_progress_dict()
    local ret_value = {}
    ret_value["48,358"] = 1
    ret_value["6357,671"] = 8868



--    io.flush()
--    local temp = io.open("test_lua_search.txt","w")
--    local file = io.open("trajectory_test.csv", "r");


    for line in file:lines() do
	local temp_split = split(line, ",")
	local temp_key = temp_split[1] .. "," .. temp_split[2]
	local temp_value = temp_split[3]
	ret_dict[temp_key] = temp_value
	level_dict_len = level_dict_len + 1
    end
    io.close(file)

    return ret_value
end

level_progress_dict = get_level_progress_dict()
--]=====]


--[=====[ 
--]=====]

