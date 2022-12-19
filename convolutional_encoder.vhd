library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity project_reti_logiche is
port (
i_clk : in std_logic;
i_rst : in std_logic;
i_start : in std_logic;
i_data : in std_logic_vector(7 downto 0);
o_address : out std_logic_vector(15 downto 0);
o_done : out std_logic;
o_en : out std_logic;
o_we : out std_logic;
o_data : out std_logic_vector (7 downto 0)
);
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

--macchina a stati
signal is_first_round: BOOLEAN;
signal i_addr: STD_LOGIC_VECTOR(15 downto 0);

signal word_count: STD_LOGIC_VECTOR(7 downto 0); 
signal w: STD_LOGIC_VECTOR(7 downto 0);
signal pos_w: INTEGER;

signal uk: STD_LOGIC;
signal q0: STD_LOGIC;
signal q1: STD_LOGIC;
signal p1k: STD_LOGIC;
signal p2k: STD_LOGIC;


 signal pos_z: INTEGER;
signal z: STD_LOGIC_VECTOR(7 downto 0); 

signal is_end: BOOLEAN;
signal o_addr : STD_LOGIC_VECTOR(15 downto 0);

type STATE is(RST,READ_PREP, READ_WAIT,READ_WORD, BIT_SEL, PK_CALC, Z_CALC, WRITE_WORD, END_WRITE, FINISH_WORD,FINISH);
signal next_state: STATE;
begin


process(i_clk, i_rst)
begin
   
        if(i_rst='1') then
            next_state<=RST;
        elsif(i_rst='0' and rising_edge(i_clk)) then
            case next_state is
            when RST =>
                is_first_round<=true;
                i_addr<="0000000000000000";
                word_count<="00000000";
                pos_w<=7;
                uk<='U';
                q0<='U';
                q1<='U';
                p1k<='U';
                p2k<='U';
                pos_z<=7;
                z<="00000000"; 
                o_addr<="0000001111101000";
                o_address<="0000000000000000";
                o_done<='0';
                 
                if(i_start='1') then
                    next_state<=READ_PREP;
                end if;
                
               
                
            when READ_PREP=>
                if(is_first_round=false and word_count="00000000") then
                    o_done<='1';
                    next_state<=RST;
                else
                    o_address<=i_addr;
                    o_en<='1';
                    o_we<='0';
                    pos_w<=7; 
                    pos_z<=7;  
                    is_end<=false;
                    i_addr<=i_addr+1;
                    next_state<=READ_WAIT;
                end if;
            when READ_WAIT=>
                 next_state<=READ_WORD;
                 
            when READ_WORD=>
                if(is_first_round=false) then
                    w<=i_data;
                    next_state<=BIT_SEL;
                elsif(is_first_round=true) then
                    word_count<=i_data;
                    is_first_round<=false; 
                        next_state<=READ_PREP;
                end if;
                
             
             when BIT_SEL=>
                if(pos_w>-1)then
                   uk<=w(pos_w);
                   pos_w<=pos_w-1;
                end if;
                if(uk='0' or uk='1') then
                    q0<=uk;
                end if;
                if(q0='0' or q0='1') then 
                    q1<=q0;
                end if;
                next_state<=PK_CALC;
                
             when PK_CALC =>
                if((q0='0' or q0='1') and (q1='0'or q1='1'))then
                    p1k<=uk xor q1;
                    p2k<= (uk xor q0) xor q1;
                elsif(q0='0' or q0='1') then
                    p1k<=uk;
                    p2k<=uk xor q0;
                else
                    p1k<=uk;
                    p2k<=uk;  
                end if;             
                next_state<=Z_CALC;
                
             when Z_CALC =>
                z(pos_z)<=p1k;
                z(pos_z-1)<=p2k;
                 pos_z<=pos_z-2;
                 if(pos_z-1=0) then 
                      next_state<=WRITE_WORD;
                 else
                    next_state<=BIT_SEL;
                end if;
               
                 
             when WRITE_WORD =>
             o_address<=o_addr;
             o_en<='1';
             o_we<='1';
             o_data<=z;
             next_state<=END_WRITE;
                
             when END_WRITE =>
             o_we<='0';
             o_addr<=o_addr+1;
              if(is_end=true) then                 
                 next_state<=FINISH_WORD;
              elsif(is_end=false)then
                 is_end<=true;
                 z<="00000000";
                 pos_z<=7;
                 next_state<=BIT_SEL;
           end if;
             
             when FINISH_WORD =>
                if(word_count>1)then
                    word_count<=word_count-1;
                     next_state<=READ_PREP;
                 else
                    o_done<='1';
                    next_state<=FINISH;
            end if;    
            
            
            when FINISH =>
            if(i_start='1') then
                next_state<=FINISH;
            else
                o_done<='0';
                next_state<=RST;
            end if;
        end case;     
       end if;
 end process;               
            

end Behavioral;
