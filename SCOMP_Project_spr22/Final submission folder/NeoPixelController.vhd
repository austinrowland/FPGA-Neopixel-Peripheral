-- WS2812 communication interface starting point for
-- ECE 2031 final project spring 2022.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity NeoPixelController is

	port(
		clk_10M   : in   std_logic;
		resetn    : in   std_logic;
		io_write  : in   std_logic ;
		cs_addr   : in   std_logic ;
		cs_data   : in   std_logic ;
		data_in   : in   std_logic_vector(15 downto 0);
		sda       : out  std_logic;
		mode24	 : in   std_logic;
		modeAll	 : in	  std_logic;
		modeAuto	 : in	  std_logic;
		modeGrad  : in   std_logic;
		modeFade	 : in	  std_logic;
		modeFlow	 : in	  std_logic
	); 

end entity;

architecture internals of NeoPixelController is
	
	-- Signals for the RAM read and write addresses
	signal ram_read_addr, ram_write_addr : std_logic_vector(7 downto 0);
	-- RAM write enable
	signal ram_we : std_logic;
	signal red, green, blue, brighten, increment: boolean;
	signal redVector, greenVector, blueVector: std_logic_vector(7 downto 0);

	-- Signals for data coming out of memory
	signal ram_read_data : std_logic_vector(23 downto 0);
	-- Signal to store the current output pixel's color data
	signal pixel_buffer : std_logic_vector(23 downto 0);

	-- Signal SCOMP will write to before it gets stored into memory
	signal ram_write_buffer : std_logic_vector(23 downto 0);

	-- RAM interface state machine signals
	type write_states is (idle16, storing16, idle24, storing24, idleAll, storingAll,idleAuto, storingAuto, idleGrad, storingGrad, idleFade, storingFade, inAndOut, idleFlow, storingFlow, colorFlow);
	signal wstate: write_states;
	
	signal count : integer range 0 to 1001;

	
begin

	-- This is the RAM that will store the pixel data.
	-- It is dual-ported.  SCOMP will access port "A",
	-- and the NeoPixel controller will access port "B".
	pixelRAM : altsyncram
	GENERIC MAP (
		address_reg_b => "CLOCK0",
		clock_enable_input_a => "BYPASS",
		clock_enable_input_b => "BYPASS",
		clock_enable_output_a => "BYPASS",
		clock_enable_output_b => "BYPASS",
		indata_reg_b => "CLOCK0",
		init_file => "pixeldata.mif",
		intended_device_family => "Cyclone V",
		lpm_type => "altsyncram",
		numwords_a => 256,
		numwords_b => 256,
		operation_mode => "BIDIR_DUAL_PORT",
		outdata_aclr_a => "NONE",
		outdata_aclr_b => "NONE",
		outdata_reg_a => "UNREGISTERED",
		outdata_reg_b => "UNREGISTERED",
		power_up_uninitialized => "FALSE",
		read_during_write_mode_mixed_ports => "OLD_DATA",
		read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
		read_during_write_mode_port_b => "NEW_DATA_NO_NBE_READ",
		widthad_a => 8,
		widthad_b => 8,
		width_a => 24,
		width_b => 24,
		width_byteena_a => 1,
		width_byteena_b => 1,
		wrcontrol_wraddress_reg_b => "CLOCK0"
	)
	PORT MAP (
		address_a => ram_write_addr,
		address_b => ram_read_addr,
		clock0 => clk_10M,
		data_a => ram_write_buffer,
		data_b => x"000000",
		wren_a => ram_we,
		wren_b => '0',
		q_b => ram_read_data
	);
	


	-- This process implements the NeoPixel protocol by
	-- using several counters to keep track of clock cycles,
	-- which pixel is being written to, and which bit within
	-- that data is being written.
	process (clk_10M, resetn)
		-- protocol timing values (in 100s of ns)
		constant t1h : integer := 8; -- high time for '1'
		constant t0h : integer := 3; -- high time for '0'
		constant ttot : integer := 12; -- total bit time
		
		constant npix : integer := 256;

		-- which bit in the 24 bits is being sent
		variable bit_count   : integer range 0 to 31;
		-- counter to count through the bit encoding
		variable enc_count   : integer range 0 to 31;
		-- counter for the reset pulse
		variable reset_count : integer range 0 to 1000;
		-- Counter for the current pixel
		variable pixel_count : integer range 0 to 255;
		
		
	begin
		
		if resetn = '0' then
			-- reset all counters
			bit_count := 23;
			enc_count := 0;
			reset_count := 1000;
			-- set sda inactive
			sda <= '0';

		elsif (rising_edge(clk_10M)) then

			-- This IF block controls the various counters
			if reset_count /= 0 then -- in reset/end-of-frame period
				-- during reset period, ensure other counters are reset
				pixel_count := 0;
				bit_count := 23;
				enc_count := 0;
				-- decrement the reset count
				reset_count := reset_count - 1;
				-- load data from memory
				pixel_buffer <= ram_read_data;
				
			else -- not in reset period (i.e. currently sending data)
				-- handle reaching end of a bit
				if enc_count = (ttot-1) then -- is end of this bit?
					enc_count := 0;
					-- shift to next bit
					pixel_buffer <= pixel_buffer(22 downto 0) & '0';
					if bit_count = 0 then -- is end of this pixels's data?
						bit_count := 23; -- start a new pixel
						pixel_buffer <= ram_read_data;
						if pixel_count = npix-1 then -- is end of all pixels?
							-- begin the reset period
							reset_count := 1000;
						else
							pixel_count := pixel_count + 1;
						end if;
					else
						-- if not end of this pixel's data, decrement count
						bit_count := bit_count - 1;
					end if;
				else
					-- within a bit, count to achieve correct pulse widths
					enc_count := enc_count + 1;
				end if;
			end if;
			
			
			-- This IF block controls the RAM read address to step through pixels
			if reset_count /= 0 then
				ram_read_addr <= x"00";
			elsif (bit_count = 1) AND (enc_count = 0) then
				-- increment the RAM address as each pixel ends
				ram_read_addr <= ram_read_addr + 1;
			end if;
			
			
			-- This IF block controls sda
			if reset_count > 0 then
				-- sda is 0 during reset/latch
				sda <= '0';
			elsif 
				-- sda is 1 in the first part of a bit.
				-- Length of first part depends on if bit is 1 or 0
				( (pixel_buffer(23) = '1') and (enc_count < t1h) )
				or
				( (pixel_buffer(23) = '0') and (enc_count < t0h) )
				then sda <= '1';
			else
				sda <= '0';
			end if;
			
		end if;
	end process;
	
	
	
	process(clk_10M, resetn, cs_addr)
	begin
		-- For this implementation, saving the memory address
		-- doesn't require anything special.  Just latch it when
		-- SCOMP sends it.
--		if resetn = '0' then
--			ram_write_addr <= x"00";
--		elsif rising_edge(clk_10M) then
--			-- If SCOMP is writing to the address register...
--			if (io_write = '1') and (cs_addr='1') then
--				ram_write_addr <= data_in(7 downto 0);
--			-- If SCOMP is reading from the memory register...
--			elsif (io_write = '0') and (cs_data='1') then
--				ram_write_addr <= ram_write_addr + 1;
--			-- SCOMP incrementing after the writing state
--			elsif (wstate = storing16) then
--				ram_write_addr <= ram_write_addr + 1;
--			end if;
--		end if;
--	
	
		-- The sequnce of events needed to store data into memory will be
		-- implemented with a state machine.
		-- Although there are ways to more simply connect SCOMP's I/O system
		-- to an altsyncram module, it would only work with under specific 
		-- circumstances, and would be limited to just simple writes.  Since
		-- you will probably want to do more complicated things, this is an
		-- example of something that could be extended to do more complicated
		-- things.
		-- Note that 'ram_we' is *not* implemented as a Moore output of this state
		-- machine, because Moore outputs are susceptible to glitches, and
		-- that's a bad thing for memory control signals.
		if resetn = '0' then
			wstate <= idle16;
			ram_we <= '0';
			ram_write_buffer <= x"000000";
			ram_write_addr <= x"00";
			red <= (false);
			blue <= (false);
			green <= (false);
			brighten <= (false);
			increment <= (false);
			count <= 0;
			-- Note that resetting this device does NOT clear the memory.
			-- Clearing memory would require cycling through each address
			-- and setting them all to 0.
		elsif rising_edge(clk_10M) then
			case wstate is
			
			when idle16 =>
				if (io_write = '1') then
					if (cs_data='1') then
					-- latch the current data into the temporary storage register,
					-- because this is the only time it'll be available.
					-- Convert RGB565 to 24-bit color
					ram_write_buffer <= data_in(10 downto 5) & "00" & data_in(15 downto 11) & "000" & data_in(4 downto 0) & "000";
					-- can raise ram_we on the upcoming transition, because data
					-- won't be stored until next clock cycle.
					ram_we <= '1';
					-- Change state
					wstate <= storing16;
					elsif (mode24='1') then
						wstate <= idle24;
					elsif (modeAll='1') then
						wstate <= idleAll;
					elsif (modeAuto='1') then
						wstate <= idleAuto;
					elsif (modeGrad='1') then
						wstate <= idleGrad;
					elsif (modeFade='1') then
						wstate <= idleFade;
					elsif (modeFlow= '1') then
						wstate <= idleFlow;
					elsif (cs_addr='1') then
						ram_write_addr <= data_in(7 downto 0);
					end if;
				end if;
			
			when storing16 =>
				-- All that's needed here is to lower ram_we.  The RAM will be
				-- storing data on this clock edge, so ram_we can go low at the
				-- same time.
				ram_we <= '0';
				wstate <= idle16;
				
			when idle24 =>
				if (io_write = '1') and (cs_data='1') then
					if (red = true) and (green = true) then
						blueVector <= data_in(7 downto 0);
						red <= false;
						green <= false;
						ram_write_buffer <= redVector(7 downto 0) & greenVector(7 downto 0) & blueVector(7 downto 0);
						ram_we <= '1';
						wstate <= storing24;
						-- set blue
						-- set red and green to false
						-- put ram write stuff and change state 
					elsif (red = true) and (green = false) then
						greenVector <= data_in(7 downto 0);
						green <= true;
					elsif (red = false) then
						redVector <= data_in(7 downto 0);
						red <= true;
					end if;
				elsif (io_write = '1') and (cs_addr='1') then
					ram_write_addr <= data_in(7 downto 0);
				end if;
				
			when storing24 =>
				-- All that's needed here is to lower ram_we.  The RAM will be
				-- storing data on this clock edge, so ram_we can go low at the
				-- same time.
				ram_we <= '0';
				wstate <= idle16;
				
			when idleAll =>
				if(io_write = '1') and (cs_data = '1') then
					ram_write_buffer <= data_in(10 downto 5) & "00" & data_in(15 downto 11) & "000" & data_in(4 downto 0) & "000";
					ram_we <= '1';
					ram_write_addr <= x"00";
					wstate <= storingAll;
				end if;
				
			when storingAll =>
				if(ram_write_addr = x"FF") then
					ram_we <= '0';
					wstate <= idle16;
				end if;
				ram_write_addr <= ram_write_addr + 1;
				
			when idleAuto =>
				if (io_write = '1') then
					if (cs_data='1') then
					-- latch the current data into the temporary storage register,
					-- because this is the only time it'll be available.
					-- Convert RGB565 to 24-bit color
					ram_write_buffer <= data_in(10 downto 5) & "00" & data_in(15 downto 11) & "000" & data_in(4 downto 0) & "000";
					-- can raise ram_we on the upcoming transition, because data
					-- won't be stored until next clock cycle.
					ram_we <= '1';
					-- Change state
					wstate <= storingAuto;

					elsif (cs_addr='1') then
						ram_write_addr <= data_in(7 downto 0);
					end if;
			
			-- If SCOMP is reading from the memory register...
--				
				elsif (io_write = '0') then
					if (cs_data='1') then
						ram_write_addr <= ram_write_addr + 1;
					end if;
				end if;
			
			when storingAuto =>
				-- All that's needed here is to lower ram_we.  The RAM will be
				-- storing data on this clock edge, so ram_we can go low at the
				-- same time.
				ram_we <= '0';
				ram_write_addr <= ram_write_addr + 1;
				wstate <= idle16;
				
			when idleFade =>
				if(io_write = '1') and (cs_data = '1') then
					greenVector <= data_in(10 downto 5) & "00";
					blueVector <= data_in(15 downto 11) & "000";
					redVector <= data_in(4 downto 0) & "000";
					ram_write_buffer <= redVector(7 downto 0) & greenVector(7 downto 0) & blueVector(7 downto 0);
					ram_we <= '1';
					ram_write_addr <= x"00";
					wstate <= storingFade;
--				elsif (mode24='1') then
--					wstate <= idle24;
--				elsif (modeAll='1') then
--					wstate <= idleAll;
--				elsif (modeAuto='1') then
--					wstate <= idleAuto;
--				elsif (modeGrad= '1') then
--					wstate <= idleGrad;
--				elsif (modeFade= '1') then
--					wstate <= idleFade;
--				end if
				end if;
				
			when storingFade =>
				if(ram_write_addr = x"FF") then
					ram_we <= '0';
					wstate <= inAndOut;
				else
					ram_write_addr <= ram_write_addr + 1;
				end if;
				
			when inAndOut =>
			--ram_write_buffer <= "111111111111111111111111";
				if (count = 1000) then
					if(brighten = (false)) then
						greenVector <= greenVector - 1;
						blueVector <= blueVector - 1;
						redVector <= redVector - 1;
					
					else
						greenVector <= greenVector + 1;
						blueVector <= blueVector + 1;
						redVector <= redVector + 1;
					end if;
					count <= 0;
				else
					count <= count + 1;
				end if;
				
				if(blueVector="11111111") or (redVector="11111111") or (greenVector="11111111") then --will detect if red vector becomes brightest or dimmest, then reverse direction. check if this is 6 binary bits or needs to be more or less (the "000000" vectors)
					brighten <= (false);
				end if;
				
				if (blueVector="00000000") or (redVector="00000000") or (greenVector="00000000") then
					brighten <= (true);
				end if;
				
				ram_write_buffer <= redVector(7 downto 0) & greenVector(7 downto 0) & blueVector(7 downto 0);
				ram_we <= '1';
				ram_write_addr <= x"00";
				wstate<=storingFade;
				
			when idleFlow =>

                if(io_write = '1') and (cs_data = '1') then
                    greenVector <= data_in(10 downto 5) & "00";
                    blueVector <= data_in(15 downto 11) & "000";
                    redVector <= data_in(4 downto 0) & "111";
                    ram_write_buffer <= redVector(7 downto 0) & greenVector(7 downto 0) & blueVector(7 downto 0);
                    ram_we <= '1';
                    ram_write_addr <= x"00";
                    wstate <= storingFlow;
                end if;

            when storingFlow =>

                if(ram_write_addr = x"FF") then
                    ram_we <= '0';
                    wstate <= colorFlow;
                else 
                    ram_write_addr <= ram_write_addr + 1; 
                end if;
					 
			 when colorFlow =>

			 if (count = 500) then

				  if ((redVector = "11111111") and (greenVector = "00000000" or greenVector < "11111111") and (blueVector = "00000000")) then --red 

						greenVector <= greenVector + 1;

				  elsif ((redVector = "11111111" or redVector > "00000000") and (greenVector = "11111111") and (blueVector = "00000000")) then --yellow

						redVector <= redVector - 1;

				  elsif ((redVector = "00000000") and (greenVector = "11111111") and (blueVector = "00000000" or blueVector < "11111111")) then --green

						blueVector <= blueVector + 1;

				  elsif ((redVector = "00000000") and (greenVector = "11111111" or greenVector > "00000000") and (blueVector = "11111111")) then --cyan 

						greenVector <= greenVector - 1;

				  elsif ((redVector = "00000000" or redVector < "11111111") and (greenVector = "00000000") and (blueVector = "11111111")) then --blue

						redVector <= redVector + 1;

				  elsif ((redVector = "11111111") and (greenVector = "00000000") and (blueVector = "11111111" or blueVector > "00000000")) then --pink

						blueVector <= blueVector - 1;
				  else 

						redVector <= "11111111";
						greenVector <= "00000000";
						blueVector <= "00000000";

              end if;
                  count <= 0;

              else
                  count <= count + 1;
              end if;

                ram_write_buffer <= redVector(7 downto 0) & greenVector(7 downto 0) & blueVector(7 downto 0);
                ram_we <= '1';
                ram_write_addr <= x"00";
                wstate <= storingFlow;

			 when idleGrad =>
            
                if(io_write = '1') and (cs_data = '1') then
                
                    greenVector <= "00" & data_in(10 downto 5);
                    blueVector <= "000" & data_in(15 downto 11);
                    redVector <= "000" & data_in(4 downto 0);
                    
                    ram_write_buffer <= redVector(7 downto 0) & greenVector(7 downto 0) & blueVector(7 downto 0);
--                    ram_write_buffer <= data_in(10 downto 5) & "00" & data_in(15 downto 11) & "000" & data_in(4 downto 0) & "000";
                    ram_we <= '1';
                    ram_write_addr <= x"00";
--                    ram_write_addr <= ram_write_addr + 1;

                    wstate <= storingGrad;
                    
                end if;
            
            when storingGrad =>
                
                if(ram_write_addr = x"FF") then
                    ram_we <= '0';
                    wstate <= idleGrad;
                end if;
                -- update color by incrememnt here?
                
                ram_write_addr <= ram_write_addr + 1;
--                
                if(((greenVector) > 128) and ((blueVector) > 128) and ((redVector) > 128)) then -- if all colors are greater than 128        
                
                    increment <= (false);
                    
                    if(((greenVector)) > ((redVector))) then -- if green is greater than red ; we want the highest
                        if ((greenVector) >= ((blueVector))) then -- if green is greater than blue 
--                            bestVector <= greenVector;
--                            green <= (true);
                            greenVector <= greenVector - 1;
                        else 
--                            bestVector <= blueVector;
--                            blue <= (true);
                            blueVector <= blueVector - 1;
                        end if; 
                    else 
                        if ((redVector) >= ((blueVector))) then
--                            bestVector <= redVector;
--                            red <= (true);
                            redVector <= redVector - 1;
                        else 
--                            bestVector <= blueVector;
--                            blue <= (true);
                            blueVector <= blueVector - 1;
    
                        end if;
                    end if;
                    
                elsif(((greenVector) < 128) and ((blueVector) < 128) and ((redVector) < 128)) then -- if all colors less than 128
                
                    increment <= (true);
                    
                    if((greenVector) < ((redVector))) then -- if green is greater than red ; we want the highest
                        if ((greenVector) <= ((blueVector))) then -- if green is greater than blue 
--                            bestVector <= greenVector;
--                            green <= (true);
                            greenVector <= greenVector + 1;

                        else 
--                            bestVector <= blueVector;
--                            blue <= (true);
                            blueVector <= blueVector + 1;
    
                        end if; 
                    else 
                        if ((redVector) <= (blueVector)) then
--                            bestVector <= redVector;
--                            red <= (true);
                            redVector <= redVector + 1;

                        else 
--                            bestVector <= blueVector;
--                            blue <= (true);
                            blueVector <= blueVector + 1;
    
                        end if; 
                    end if;
                    
                else -- if all are whatever idk 
                
                    increment <= (true);
                    
                    if((greenVector) < ((redVector))) then 
                        if ((greenVector) <= ((blueVector))) then 
--                            bestVector <= greenVector;
--                            green <= (true);
                            greenVector <= greenVector + 1;

                        else 
--                            bestVector <= blueVector;
--                            blue <= (true);
                            blueVector <= blueVector + 1;
    
                        end if; 
							end if;
						end if;
						
                ram_write_buffer <= redVector(7 downto 0) & greenVector(7 downto 0) & blueVector(7 downto 0);
                wstate <= storingGrad;				
			when others =>
				wstate <= idle16;
			end case;
		end if;
	end process;

	
	
end internals;
