-- This code is an adaptation of Tozes' lua script for X9D.
-- As the QX7 doesn't allow functions like pixmap and can display images, all the bmp files have been replaced by text and rectangles.
-- This script is made for my model setup. You can change it if it doesn't fit your model setup.

-- function to round values to 2 decimal of precision
function round(num, decimals)
  local mult = 10^(decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

function drawArrow(x,y,direction)
  if (direction == 0) then -- down arrow
    lcd.drawLine(x+3,y  ,x+3,y+3,SOLID,FORCE)
	lcd.drawPoint(x+3,y+5)
	lcd.drawLine(x+1,y+4,x+3,y+6,SOLID,FORCE)
	lcd.drawLine(x+3,y+6,x+5,y+4,SOLID,FORCE)
  else -- up arrow
    lcd.drawLine(x+3,y+3,x+3,y+6,SOLID,FORCE)
	lcd.drawPoint(x+3,y+1)
	lcd.drawLine(x+1,y+2,x+3,y  ,SOLID,FORCE)
	lcd.drawLine(x+3,y  ,x+5,y+2,SOLID,FORCE)
  end
end

---- Screen setup
-- top left pixel coordinates
local min_x, min_y = 0, 0 
-- bottom right pixel coordinates
local max_x, max_y = 128, 63 
-- set to create a header, the grid will adjust automatically but not its content
local header_height = 0  
-- set the grid left and right coordinates; leave space left and right for batt and rssi
local grid_limit_left, grid_limit_right = 20, 108 
-- calculated grid dimensions
local grid_width = round((max_x - (max_x - grid_limit_right) - grid_limit_left), 0)
local grid_height = round(max_y - min_y - header_height)
local grid_middle = round((grid_width / 2) + grid_limit_left, 0)
local cell_height = round(grid_height / 3, 0)

-- Batt
local max_batt = 4.2
local min_batt = 3.3
local total_max_bat = 0
local total_min_bat = 5
local total_max_curr = 0

-- RSSI
local max_rssi = 100
local min_rssi = 20

-- SWITCHES
local SW_FS = 'sc'
local SW_ARM = 'sf'
local SW_AIR = 'sc'
local SW_FMODE = 'sa'
local SW_BBOX = 'sd'
local SW_BEEPR = 'sh'

-- Data Sources
local DS_VFAS = 'VFAS'
local DS_CURR = 'Curr'
local DS_CURR_MAX = 'Curr+'
local DS_CELL = 'A4'
local DS_CELL_MIN = 'A4-'
local DS_RSSI = 'RSSI'
local DS_RSSI_MIN = 'RSSI-'


local function drawGrid(lines, cols)
  -- Grid limiter lines
  ---- Table Limits
  --lcd.drawLine(grid_limit_left, min_y, grid_limit_right, min_y, SOLID, FORCE)
  lcd.drawLine(grid_limit_left, min_y, grid_limit_left, max_y, SOLID, FORCE)
  lcd.drawLine(grid_limit_right, min_y, grid_limit_right, max_y, SOLID, FORCE)
  --lcd.drawLine(grid_limit_left, max_y, grid_limit_right, max_y, SOLID, FORCE)
  ---- Header
  --lcd.drawLine(grid_limit_left, min_y + header_height, grid_limit_right, min_y + header_height, SOLID, FORCE)
  ---- Grid
  ------ Top
  lcd.drawLine(grid_middle, min_y + header_height, grid_middle, max_y, SOLID, FORCE)
  ------ Hrznt Line 1
  lcd.drawLine(grid_limit_left, cell_height + header_height - 2, grid_limit_right, cell_height + header_height -2, SOLID, FORCE)
  lcd.drawLine(grid_limit_left, cell_height * 2 + header_height - 1, grid_limit_right, cell_height * 2 + header_height - 1, SOLID, FORCE)
end

-- Draw the battery indicator
local function drawBatt()
  local batt = getValue(DS_VFAS)
  local cell = getValue(DS_CELL)
  local curr = getValue(DS_CURR)
  local data_min_batt = getValue(DS_CELL_MIN)

  if total_max_bat<batt then
    if batt<10 then
      total_max_bat=round(batt, 2)
    else
      total_max_bat=round(batt, 1)
    end 
  end
  local cell_count = 0
  if batt>0 then
        cell_count = math.floor(batt/cell)
  end
        -- local cell = batt/cell_count

  if cell_count~=1 or cell_count~=2 or cell_count~=3 or cell_count~=4 or cell_count~=5 or cell_count~=6 then
    cell = batt/cell_count
  end
  if cell_count==0 then
    cell = 0
  end
  if total_max_curr<curr then
     total_max_curr = curr
  end
  if data_min_batt>0 and total_min_bat > 0 then   
    if total_min_bat>cell then
      total_min_bat = cell
    end
  end
    
-- Calculate the size of the level
  local total_steps = 30 
  local range = max_batt - min_batt
  local step_size = range/total_steps
  local current_level = math.floor(total_steps - ((cell - min_batt) / step_size))
  if current_level>30 then
    current_level=30
  end
  if current_level<0 then
    current_level=0
  end
    --draw graphic battery level
  lcd.drawFilledRectangle(6, 2, 8, 4, SOLID)
  lcd.drawFilledRectangle(3, 5, 14, 32, SOLID)
  lcd.drawFilledRectangle(4, 6, 12, current_level, ERASE)
    
  -- Values
  lcd.drawText(2, 39, round(cell, 2),SMLSIZE)
  if batt<10 then
    lcd.drawText(2, 48, round(batt, 2),SMLSIZE)
  else
    lcd.drawText(2, 48, round(batt, 1),SMLSIZE)
  end
  
    
  lcd.drawText(1, 57, "Vbat", INVERS+SMLSIZE)
  
end




local function drawRSSI()
  local rssi = getValue(DS_RSSI)
  
  CLAMPrssi = rssi
  
  if (CLAMPrssi < min_rssi) then
    CLAMPrssi = min_rssi
  elseif (CLAMPrssi > max_rssi) then
    CLAMPrssi = max_rssi
  end
    
  local total_steps = 9
  local range = max_rssi - min_rssi
  local step_size = range/total_steps
  local current_level = math.floor((CLAMPrssi - min_rssi) / step_size)
  
  if (current_level == 9) then
    lcd.drawFilledRectangle(110   ,  2, 17   , 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 3,  6, 17- 3, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 6, 10, 17- 6, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 8, 14, 17- 8, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+10, 18, 17-10, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+12, 22, 17-12, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+13, 26, 17-13, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+14, 30, 17-14, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+15, 34, 17-15, 3, BLA_DEFAULT)
  elseif (current_level == 8) then
    lcd.drawFilledRectangle(110   ,  3, 17   , 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 3,  6, 17- 3, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 6, 10, 17- 6, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 8, 14, 17- 8, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+10, 18, 17-10, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+12, 22, 17-12, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+13, 26, 17-13, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+14, 30, 17-14, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+15, 34, 17-15, 3, BLA_DEFAULT)
  elseif (current_level == 7) then
    lcd.drawFilledRectangle(110   ,  3, 17   , 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 3,  7, 17- 3, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 6, 10, 17- 6, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 8, 14, 17- 8, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+10, 18, 17-10, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+12, 22, 17-12, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+13, 26, 17-13, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+14, 30, 17-14, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+15, 34, 17-15, 3, BLA_DEFAULT)
  elseif (current_level == 6) then
    lcd.drawFilledRectangle(110   ,  3, 17   , 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 3,  7, 17- 3, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 6, 11, 17- 6, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 8, 14, 17- 8, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+10, 18, 17-10, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+12, 22, 17-12, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+13, 26, 17-13, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+14, 30, 17-14, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+15, 34, 17-15, 3, BLA_DEFAULT)
  elseif (current_level == 5) then
    lcd.drawFilledRectangle(110   ,  3, 17   , 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 3,  7, 17- 3, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 6, 11, 17- 6, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 8, 15, 17- 8, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+10, 18, 17-10, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+12, 22, 17-12, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+13, 26, 17-13, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+14, 30, 17-14, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+15, 34, 17-15, 3, BLA_DEFAULT)
  elseif (current_level == 4) then
    lcd.drawFilledRectangle(110   ,  3, 17   , 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 3,  7, 17- 3, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 6, 11, 17- 6, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 8, 15, 17- 8, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+10, 19, 17-10, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+12, 22, 17-12, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+13, 26, 17-13, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+14, 30, 17-14, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+15, 34, 17-15, 3, BLA_DEFAULT)
  elseif (current_level == 3) then
    lcd.drawFilledRectangle(110   ,  3, 17   , 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 3,  7, 17- 3, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 6, 11, 17- 6, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 8, 15, 17- 8, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+10, 19, 17-10, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+12, 23, 17-12, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+13, 26, 17-13, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+14, 30, 17-14, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+15, 34, 17-15, 3, BLA_DEFAULT)
  elseif (current_level == 2) then
    lcd.drawFilledRectangle(110   ,  3, 17   , 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 3,  7, 17- 3, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 6, 11, 17- 6, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 8, 15, 17- 8, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+10, 19, 17-10, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+12, 23, 17-12, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+13, 27, 17-13, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+14, 30, 17-14, 3, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+15, 34, 17-15, 3, BLA_DEFAULT)
  elseif (current_level == 1) then
    lcd.drawFilledRectangle(110   ,  3, 17   , 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 3,  7, 17- 3, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 6, 11, 17- 6, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 8, 15, 17- 8, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+10, 19, 17-10, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+12, 23, 17-12, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+13, 27, 17-13, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+14, 31, 17-14, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+15, 34, 17-15, 3, BLA_DEFAULT)
  elseif (current_level == 0) then
    lcd.drawFilledRectangle(110   ,  3, 17   , 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 3,  7, 17- 3, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 6, 11, 17- 6, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+ 8, 15, 17- 8, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+10, 19, 17-10, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+12, 23, 17-12, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+13, 27, 17-13, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+14, 31, 17-14, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+15, 35, 17-15, 1, BLA_DEFAULT)
  else
    lcd.drawFilledRectangle(110+13,  3, 17-13, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+13,  7, 17-13, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+13, 11, 17-13, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+13, 15, 17-13, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+13, 19, 17-13, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+13, 23, 17-13, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+13, 27, 17-13, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+13, 31, 17-13, 1, BLA_DEFAULT)
    lcd.drawFilledRectangle(110+13, 35, 17-13, 1, BLA_DEFAULT)
  end
	
  -- Display durrent RSSI value
  if (rssi==100) then
    lcd.drawText(111, 42, round(rssi, 0))
  else
    lcd.drawText(110, 38, round(rssi, 0), DBLSIZE)
  end
  lcd.drawText(109, 57, "rssi", INVERS+SMLSIZE)
end



-- Top Left cell -- Flight mode
local function cell_TL()
  local x1 = grid_limit_left + 1
  local y1 = min_y + header_height - 3

  -- FMODE
  local f_mode = "UNKN"
  local fm = getValue(SW_FMODE)
	if fm < -1000 then
		f_mode = "ANGL"
	elseif (-10 < fm and fm < 10) then
		f_mode = "HRZN"
	elseif fm > 1000 then
	    f_mode = "ACRO"
	end
  lcd.drawText(x1 + 4, y1 + 6, f_mode, MIDSIZE)
end


-- Top Right cell -- Switch statuses (enabled, disabled)
local function cell_TR()
  local x1 = grid_middle + 1
  local y1 = min_y + header_height + 1

  local armed = getValue(SW_ARM)  -- arm
  local airmode = getValue(SW_AIR)  -- airmode
  local failsafe = getValue(SW_FS)  -- failsafe
  local bbox = getValue(SW_BBOX)  -- blackbox
  local beepr = getValue(SW_BEEPR)  -- blackbox
  local fm = getValue(SW_FMODE)

  if (armed < 10 and failsafe < 0) then
        lcd.drawText(x1 + 3, y1 + 1, "Arm", SMLSIZE)
  elseif (failsafe < 0) then
        lcd.drawText(x1 + 3, y1 + 1, "Arm", INVERS+SMLSIZE)
  end

  if (airmode < -10 and failsafe < 0) then
        lcd.drawText(x1 + 25, y1 + 1, "Air", SMLSIZE)
  elseif (failsafe < 0) then
        lcd.drawText(x1 + 25, y1 + 1, "Air", INVERS+SMLSIZE)
  end
  
  if (bbox < -10 and failsafe < 0) then
        lcd.drawText(x1 + 3, y1 + 10, "Bbx", SMLSIZE)
  elseif (failsafe < 0) then
        lcd.drawText(x1 + 3, y1 + 10, "Bbx", INVERS+SMLSIZE)
  end

  if (beepr < 10 and failsafe < 0) then
        lcd.drawText(x1 + 25, y1 + 10, "Bpr", SMLSIZE)
  elseif (failsafe < 0) then
        lcd.drawText(x1 + 25, y1 + 10, "Bpr", INVERS+SMLSIZE)
  end

 if failsafe > -10 then
        lcd.drawFilledRectangle(x1, y1, (grid_limit_right - grid_limit_left) / 2, cell_height, DEFAULT)
        lcd.drawText(x1+2, y1+2, "FailSafe", SMLSIZE+INVERS+BLINK)
        lcd.drawText(x1 + 25, y1 + 12, "Bpr", INVERS+SMLSIZE+BLINK)
 end
end




-- Middle Left cell -- Current time
local function cell_ML() 
  local x1 = grid_limit_left + 1
  local y1 = min_y + header_height + cell_height + 1
  
  local cell = round(getValue(DS_CELL), 2)
  local batt = round(getValue(DS_VFAS),1)

  drawArrow(x1,y1,0)
  lcd.drawText(x1+8,  y1, cell)
  lcd.drawText(x1+25, y1+1, "cv",SMLSIZE)
	
  drawArrow(x1,y1+9,0)
  lcd.drawText(x1+8, y1+10, batt)
  lcd.drawText(x1+25, y1+11, "v",SMLSIZE)

end


-- Middle right cell -- Timer1
local function cell_MR() 
  local x1 = grid_middle + 1
  local y1 = min_y + header_height + cell_height + 1

  lcd.drawText(x1, y1, "T1", INVERS)

  -- Show timer
  timer = model.getTimer(0)
  s = timer.value
  time = string.format("%.2d:%.2d:%.2d", s/(60*60), s/60%60, s%60)
  lcd.drawText(x1 + 4, y1 + 10, time)
end


-- Bottom Left cell
local function cell_BL()

  local x1 = grid_limit_left + 1
  local y1 = min_y + header_height + cell_height*2 + 2

  local curr = round(getValue(DS_CURR),2)
  local currmax = round(getValue(DS_CURR_MAX),2)
  
  --drawArrow(x1,y1,1)
  lcd.drawText(x1+8,  y1, curr)
  lcd.drawText(x1+25, y1+1, "A",SMLSIZE)
	
  drawArrow(x1,y1+9,1)
  lcd.drawText(x1+8, y1+10, currmax)
  lcd.drawText(x1+25, y1+11, "A",SMLSIZE)
  
end


-- Bottom right cell -- Timer2
local function cell_BR() 
  local x1 = grid_middle + 1
  local y1 = min_y + header_height + cell_height * 2 + 1

  lcd.drawText(x1, y1, "T2", INVERS)
  -- Show timer
  timer = model.getTimer(1)
  s = timer.value
  time = string.format("%.2d:%.2d:%.2d", s/(60*60), s/60%60, s%60)
  lcd.drawText(x1 + 4, y1 + 10, time)
end

-- Execute
local function run(event)
  lcd.clear()
  cell_TL()
  cell_TR()
  cell_ML()
  cell_MR()
  cell_BL()
  cell_BR()
  drawBatt()
  drawRSSI()
  drawGrid()
end

return{run=run, init=init_func}