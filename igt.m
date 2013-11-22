% *. Introdution to this script:
% 
% This matlab-based script implements a version of the modified Iowa Gambling Task (IGT) as described in:
% Cauffman, E., Shulman, E.P, Steinberg, L., Claus, E., Marie T. Banich, M.T., Sandra Graham, S., Jennifer Woolard, J. (2010). Age Differences in Affective Decision Making as Indexed by Performance on the Iowa Gambling Task. Developmental Psychology, Vol. 46, No. 1, 193-207.
% 
% As for the original Iowa Gambling Task (IGT) please refer to the paper published earlier as shown below: 
% Bechara A., Damasio A. R., Damasio H., Anderson S. W. (1994). Insensitivity to future consequences following damage to human prefrontal cortex. Cognition, 50, 7-15 .
% 
% *. To perform and quit the script:
% 
% type 'igt(Subject_ID)' in Matlab command window, ex. igt(1), igt(2)....or igt(n).
% for quiting type 'ESC'. Task result is stored in "result" folder with '.mat' extension.
% 
% *. Experimental instruction:
% 
% "In this game, your goal is to win as much money as possible.
% For each round, one of the four decks of cards will be preselected, you can make a decision between playing or passing a card from this deck. You will have 4s to decide.
% If you PLAY, you can win but also lose money (or neither win nor lose money). If you PASS you neither win nor lose any money. Some decks will be more profitable than others.
% Place your index fingers on the 'a' and 'l' keys on your keyboard. To PLAY, press the 'a' key. To PASS, press the 'l' -key. You start with $2000."
% 
% Wrote by bo zhang, Updated on 22/11/2013
% bozhang.neuro@gmail.com
% 


function igt(subject_ID)

Screen('Preference', 'SkipSyncTests', 1); % skip sync-tests for retina display
[wPtr,wRect] = Screen('OpenWindow', 0);
w = wRect(RectRight);
h = wRect(RectBottom);
KbName('UnifyKeyNames');    % keynames for all types of keyboard
white = WhiteIndex(wPtr);  % gray color for the text "previous total"
black = BlackIndex(wPtr);
gray = (white + black) / 2;

%load images as decks
img = imread('./images/deck.jpg');
deck_width =144;
deck_height = 206;
t1 = Screen('MakeTexture', wPtr, img);
% show decks
deck_A = [w/2-3*w/16-2*deck_width, h/5, w/2-3*w/16-deck_width, h/5+deck_height];
deck_B = [w/2-w/16-deck_width, h/5, w/2-w/16, h/5+deck_height];
deck_C = [w/2+w/16, h/5, w/2+w/16+deck_width, h/5+deck_height];
deck_D = [w/2+3*w/16+deck_width, h/5,w/2+3*w/16+2*deck_width, h/5+deck_height];
Screen('DrawTexture', wPtr, t1, [], deck_A);
Screen('DrawTexture', wPtr, t1, [], deck_B);
Screen('DrawTexture', wPtr, t1, [], deck_C);
Screen('DrawTexture', wPtr, t1, [], deck_D);
Screen('TextFont',wPtr, 'Arial');
Screen('TextSize',wPtr, 35);
Screen('DrawText', wPtr, 'Deck A', w/2-3*w/16-2*deck_width+deck_width/10, h/5+deck_height+h/50,0)
Screen('DrawText', wPtr, 'Deck B', w/2-w/16-deck_width+deck_width/10, h/5+deck_height+h/50,0)
Screen('DrawText', wPtr, 'Deck C', w/2+w/16+deck_width/10, h/5+deck_height+h/50,0)
Screen('DrawText', wPtr, 'Deck D', w/2+3*w/16+deck_width+deck_width/10, h/5+deck_height+h/50,0)

% show experimental title
Screen('TextFont',wPtr, 'Arial');
Screen('TextSize',wPtr, 55);
[nx, ny, bbox] = DrawFormattedText(wPtr, 'Iowa Gambling Test', 'center', h/11, 0);

% show instruction
Screen('TextFont',wPtr, 'Arial');
Screen('TextSize',wPtr, 30);
fid = fopen('instruction_text.txt', 'rt');
mytext = '';
tline = fgets(fid);
while ischar(tline)
    tline = fgets(fid);
    mytext = [mytext, tline];
end
fclose(fid);
[nx, ny, bbox] = DrawFormattedText(wPtr, mytext, w/2-w/3, h/2, 0, 85);

% show start button
Screen('TextFont',wPtr, 'Arial');
Screen('TextSize',wPtr, 35);
[nx, ny, bbox] = DrawFormattedText(wPtr, 'PRESS <SPACE> TO START', 'center', 11*h/12, [0, 0, 255]);
Screen('Flip',wPtr)

%wait for pressing space key and quit key
while 1
    [secs, KeyCode, deltaSecs] = KbWait([], 3);
    WaitSecs(0.001);
    if KeyCode(KbName('SPACE'))
        break;
    end
    if KeyCode(KbName('escape'))
        Screen('CloseAll');
        return;
    end
end

%define decks and calculation elements
deck = [deck_A; deck_B; deck_C;  deck_D];
randDeck = zeros(121,1);
net_change = zeros(121, 1);
net_change (1,1)= 0;
Current_total = zeros(121,1);
Current_total(1,1) = 2000;
Previous_total = zeros(121, 1);
Previous_total (1,1) = 0;
play_or_pass = cell(121,1);

%define arrays for losses.
deck1_losses_array = [0, 0, 0, 0, 0, -150, -200, -250, -300, -350];
deck1_losses_d = zeros(120,1);
deck2_losses_array = [0, 0, 0, 0, 0, 0, 0, 0, 0, -1250];
deck2_losses_d = zeros(120,1);
deck3_losses_array = [0, 0, 0, 0, 0, -50, -50, -75, -75, -75];
deck3_losses_a = zeros(120,1);
deck4_losses_array = [0, 0, 0, 0, 0, 0, 0, 0, 0, -250];
deck4_losses_a = zeros(120,1);

% monetary distribution and display
deck1_gains_d = 100;
deck2_gains_d = 100;
deck3_gains_a = 50;
deck4_gains_a = 50;

%  subjects' response
dur_rt = cell(121,0);
dur_deck = 4;

%-------------------------------------------------------------------------------------------
% trial is coming, is coming, is coming, is coming, is coming, is coming
%-------------------------------------------------------------------------------------------
for deck_jump = 1:120
    
    % randomize deck selection
    randDeck(deck_jump+1,1) = randsample(length(deck), 1);
    selected_deck = deck(randDeck(deck_jump+1,1),: );
    
    % define whether selected_deck's coordinate matchs the coordinate of defined deck
    c1=setdiff(selected_deck,deck_A);
    c2=setdiff(selected_deck,deck_B);
    c3=setdiff(selected_deck,deck_C);
    c4=setdiff(selected_deck,deck_D);
    
    %for geting deck1 negative data
    if  isempty(c1)
        if isempty (deck1_losses_array)
            deck1_losses_array = [0, 0, 0, 0, 0, -150, -200, -250, -300, -350];
        end
        the_th_ele=randsample(length(deck1_losses_array),1);
        deck1_losses_d (deck_jump,1) = deck1_losses_array (the_th_ele);
        deck1_losses_array (the_th_ele) = [];
    end
    
    %for geting deck2 negative data
    if  isempty(c2)
        if isempty (deck2_losses_array)
            deck2_losses_array = [0, 0, 0, 0, 0, 0, 0, 0, 0, -1250];
        end
        the_th_ele=randsample(length(deck2_losses_array),1);
        deck2_losses_d (deck_jump,1) = deck2_losses_array (the_th_ele);
        deck2_losses_array (the_th_ele) = [];
    end
    
    %for geting deck3 negative data
    if  isempty(c3)
        if isempty (deck3_losses_array)
            deck3_losses_array = [0, 0, 0, 0, 0, -50, -50, -75, -75, -75];
        end
        the_th_ele=randsample(length(deck3_losses_array),1);
        deck3_losses_a  (deck_jump,1) = deck3_losses_array (the_th_ele);
        deck3_losses_array (the_th_ele) = [];
    end
    
    %for geting deck4 negative data
    if  isempty(c4)
        if isempty (deck4_losses_array)
            deck4_losses_array = [0, 0, 0, 0, 0, 0, 0, 0, 0, -250];
        end
        the_th_ele=randsample(length(deck4_losses_array),1);
        deck4_losses_a (deck_jump,1) = deck4_losses_array (the_th_ele);
        deck4_losses_array (the_th_ele) = [];
    end
    
    if  isempty(c1)
        Screen('TextFont',wPtr, 'Arial');
        Screen('TextSize',wPtr, 40);
        Screen('DrawText', wPtr, 'Play - A - Key', w/2-2*w/8, h/10,0)
        Screen('DrawText', wPtr, 'Pass - l - Key', w/2+w/10, h/10,0)
        Screen('TextFont',wPtr, 'Arial');
        Screen('TextSize',wPtr, 35);
        Screen('DrawText', wPtr, 'Deck A', w/2-3*w/16-2*deck_width+deck_width/10, h/5+deck_height+h/50,0)
        Screen('DrawText', wPtr, 'Deck B', w/2-w/16-deck_width+deck_width/10, h/5+deck_height+h/50,0)
        Screen('DrawText', wPtr, 'Deck C', w/2+w/16+deck_width/10, h/5+deck_height+h/50,0)
        Screen('DrawText', wPtr, 'Deck D', w/2+3*w/16+deck_width+deck_width/10, h/5+deck_height+h/50,0)
        Current_total_pre = ['Current total: $' num2str(Current_total(deck_jump,1))];
        Previous_total_pre = ['Previous total: $' num2str(Previous_total (deck_jump,1))];
        [nx, ny, bbox] = DrawFormattedText(wPtr,Current_total_pre, 'center', 12*h/20, 0);
        [nx, ny, bbox] = DrawFormattedText(wPtr,Previous_total_pre, 'center', 13*h/20, gray);
        img = imread('./images/deckon.jpg');
        t2 = Screen('MakeTexture', wPtr, img);
        Screen('DrawTexture', wPtr, t2, [], deck_A);
        Screen('DrawTexture', wPtr, t1, [], deck_B);
        Screen('DrawTexture', wPtr, t1, [], deck_C);
        Screen('DrawTexture', wPtr, t1, [], deck_D);
        startTime = Screen('Flip',wPtr);
    end
    
    
    if  isempty(c2)
        Screen('TextFont',wPtr, 'Arial');
        Screen('TextSize',wPtr, 40);
        Screen('DrawText', wPtr, 'Play - A - Key', w/2-2*w/8, h/10,0)
        Screen('DrawText', wPtr, 'Pass - l - Key', w/2+w/10, h/10,0)
        Screen('TextFont',wPtr, 'Arial');
        Screen('TextSize',wPtr, 35);
        Screen('DrawText', wPtr, 'Deck A', w/2-3*w/16-2*deck_width+deck_width/10, h/5+deck_height+h/50,0)
        Screen('DrawText', wPtr, 'Deck B', w/2-w/16-deck_width+deck_width/10, h/5+deck_height+h/50,0)
        Screen('DrawText', wPtr, 'Deck C', w/2+w/16+deck_width/10, h/5+deck_height+h/50,0)
        Screen('DrawText', wPtr, 'Deck D', w/2+3*w/16+deck_width+deck_width/10, h/5+deck_height+h/50,0)
        Current_total_pre = ['Current total: $' num2str(Current_total(deck_jump,1))];
        Previous_total_pre = ['Previous total: $' num2str(Previous_total (deck_jump,1))];
        [nx, ny, bbox] = DrawFormattedText(wPtr,Current_total_pre, 'center', 12*h/20, 0);
        [nx, ny, bbox] = DrawFormattedText(wPtr,Previous_total_pre, 'center', 13*h/20, gray);
        img = imread('./images/deckon.jpg');
        t2 = Screen('MakeTexture', wPtr, img);
        Screen('DrawTexture', wPtr, t1, [], deck_A);
        Screen('DrawTexture', wPtr, t2, [], deck_B);
        Screen('DrawTexture', wPtr, t1, [], deck_C);
        Screen('DrawTexture', wPtr, t1, [], deck_D);
        startTime = Screen('Flip',wPtr);
    end
    
    if  isempty(c3)
        Screen('TextFont',wPtr, 'Arial');
        Screen('TextSize',wPtr, 40);
        Screen('DrawText', wPtr, 'Play - A - Key', w/2-2*w/8, h/10,0)
        Screen('DrawText', wPtr, 'Pass - l - Key', w/2+w/10, h/10,0)
        Screen('TextFont',wPtr, 'Arial');
        Screen('TextSize',wPtr, 35);
        Screen('DrawText', wPtr, 'Deck A', w/2-3*w/16-2*deck_width+deck_width/10, h/5+deck_height+h/50,0)
        Screen('DrawText', wPtr, 'Deck B', w/2-w/16-deck_width+deck_width/10, h/5+deck_height+h/50,0)
        Screen('DrawText', wPtr, 'Deck C', w/2+w/16+deck_width/10, h/5+deck_height+h/50,0)
        Screen('DrawText', wPtr, 'Deck D', w/2+3*w/16+deck_width+deck_width/10, h/5+deck_height+h/50,0)
        Current_total_pre = ['Current total: $' num2str(Current_total(deck_jump,1))];
        Previous_total_pre = ['Previous total: $' num2str(Previous_total(deck_jump,1))];
        [nx, ny, bbox] = DrawFormattedText(wPtr,Current_total_pre, 'center', 12*h/20, 0);
        [nx, ny, bbox] = DrawFormattedText(wPtr,Previous_total_pre, 'center', 13*h/20, gray);
        img = imread('./images/deckon.jpg');
        t2 = Screen('MakeTexture', wPtr, img);
        Screen('DrawTexture', wPtr, t1, [], deck_A);
        Screen('DrawTexture', wPtr, t1, [], deck_B);
        Screen('DrawTexture', wPtr, t2, [], deck_C);
        Screen('DrawTexture', wPtr, t1, [], deck_D);
        startTime = Screen('Flip',wPtr);
    end
    
    if  isempty(c4)
        Screen('TextFont',wPtr, 'Arial');
        Screen('TextSize',wPtr, 40);
        Screen('DrawText', wPtr, 'Play - A - Key', w/2-2*w/8, h/10,0)
        Screen('DrawText', wPtr, 'Pass - l - Key', w/2+w/10, h/10,0)
        Screen('TextFont',wPtr, 'Arial');
        Screen('TextSize',wPtr, 35);
        Screen('DrawText', wPtr, 'Deck A', w/2-3*w/16-2*deck_width+deck_width/10, h/5+deck_height+h/50,0)
        Screen('DrawText', wPtr, 'Deck B', w/2-w/16-deck_width+deck_width/10, h/5+deck_height+h/50,0)
        Screen('DrawText', wPtr, 'Deck C', w/2+w/16+deck_width/10, h/5+deck_height+h/50,0)
        Screen('DrawText', wPtr, 'Deck D', w/2+3*w/16+deck_width+deck_width/10, h/5+deck_height+h/50,0)
        Current_total_pre = ['Current total: $' num2str(Current_total(deck_jump,1))];
        Previous_total_pre = ['Previous total: $' num2str(Previous_total(deck_jump,1))];
        [nx, ny, bbox] = DrawFormattedText(wPtr,Current_total_pre, 'center', 12*h/20, 0);
        [nx, ny, bbox] = DrawFormattedText(wPtr,Previous_total_pre, 'center', 13*h/20, gray);
        img = imread('./images/deckon.jpg');
        t2 = Screen('MakeTexture', wPtr, img);
        Screen('DrawTexture', wPtr, t1, [], deck_A);
        Screen('DrawTexture', wPtr, t1, [], deck_B);
        Screen('DrawTexture', wPtr, t1, [], deck_C);
        Screen('DrawTexture', wPtr, t2, [], deck_D);
        startTime = Screen('Flip',wPtr);
    end
    
    
    % time to show highlighted deck is from starttime
    while GetSecs - startTime < dur_deck
        [keyisdown,secs,keycode_al] = KbCheck;
        
        %              [secs, keycode_al, deltaSecs] = KbWait
        WaitSecs(0.001);
        responseTime = secs;
        playkey = KbName('a');
        passkey = KbName('l');
        quitkey = KbName('escape');
        
        if keycode_al(quitkey)
            Screen('CloseAll');
            return;
        end
        
        if keyisdown
            if  keycode_al(playkey) && isempty(c1)
                WaitSecs(0.1);
                net_change(deck_jump+1,1) = deck1_gains_d + deck1_losses_d (deck_jump,1);
                net_income = ['Amount $' num2str(net_change(deck_jump+1,1))];
                Current_total (deck_jump+1,1) = Current_total(deck_jump,1) + net_change(deck_jump+1,1);
                Previous_total (deck_jump+1,1)= Current_total (deck_jump+1,1) - net_change(deck_jump+1,1);
                Current_total_show = ['Current total: $' num2str(Current_total (deck_jump+1,1))];
                Previous_total_show = ['Previous total: $' num2str(Previous_total (deck_jump+1,1))];
                Screen('TextFont',wPtr, 'Arial');
                Screen('TextSize',wPtr, 40);
                Screen('DrawText', wPtr, 'Play - A - Key', w/2-2*w/8, h/10,0)
                Screen('DrawText', wPtr, 'Pass - l - Key', w/2+w/10, h/10,0)
                Screen('TextFont',wPtr, 'Arial');
                Screen('TextSize',wPtr, 35);
                Screen('DrawText', wPtr, 'Deck A', w/2-3*w/16-2*deck_width+deck_width/10, h/5+deck_height+h/50,0)
                Screen('DrawText', wPtr, 'Deck B', w/2-w/16-deck_width+deck_width/10, h/5+deck_height+h/50,0)
                Screen('DrawText', wPtr, 'Deck C', w/2+w/16+deck_width/10, h/5+deck_height+h/50,0)
                Screen('DrawText', wPtr, 'Deck D', w/2+3*w/16+deck_width+deck_width/10, h/5+deck_height+h/50,0)
                if net_change(deck_jump+1,1) > 1
                    Screen('DrawText', wPtr, net_income, w/2-3*w/16-2*deck_width-deck_width/4+deck_width/5-deck_width/10, h/5+deck_height+4*h/50,[0 255 0])
                else
                    Screen('DrawText', wPtr, net_income, w/2-3*w/16-2*deck_width-deck_width/4+deck_width/5-deck_width/10, h/5+deck_height+4*h/50,[255 0 0])
                end
                [nx, ny, bbox] = DrawFormattedText(wPtr,Current_total_show, 'center', 12*h/20, 0);
                [nx, ny, bbox] = DrawFormattedText(wPtr,Previous_total_show, 'center', 13*h/20, gray);
                Screen('DrawTexture', wPtr, t2, [], deck_A);
                Screen('DrawTexture', wPtr, t1, [], deck_B);
                Screen('DrawTexture', wPtr, t1, [], deck_C);
                Screen('DrawTexture', wPtr, t1, [], deck_D);
                Screen('Flip',wPtr);
                play_or_pass{deck_jump+1,1} = 'Play';
                dur_rt {deck_jump+1,1}= responseTime - startTime;
                WaitSecs(2);
                break;
            end
            
            if  keycode_al(playkey) && isempty(c2)
                WaitSecs(0.1);
                net_change(deck_jump+1,1) = deck2_gains_d + deck2_losses_d (deck_jump,1);
                net_income = ['Amount $' num2str(net_change(deck_jump+1,1))];
                Current_total(deck_jump+1,1) = Current_total(deck_jump,1) + net_change(deck_jump+1,1);
                Previous_total (deck_jump+1,1)= Current_total(deck_jump+1,1) - net_change(deck_jump+1,1);
                Current_total_show = ['Current total: $' num2str(Current_total(deck_jump+1,1))];
                Previous_total_show = ['Previous total: $' num2str(Previous_total (deck_jump+1,1))];
                Screen('TextFont',wPtr, 'Arial');
                Screen('TextSize',wPtr, 40);
                Screen('DrawText', wPtr, 'Play - A - Key', w/2-2*w/8, h/10,0)
                Screen('DrawText', wPtr, 'Pass - l - Key', w/2+w/10, h/10,0)
                Screen('TextFont',wPtr, 'Arial');
                Screen('TextSize',wPtr, 35);
                Screen('DrawText', wPtr, 'Deck A', w/2-3*w/16-2*deck_width+deck_width/10, h/5+deck_height+h/50,0)
                Screen('DrawText', wPtr, 'Deck B', w/2-w/16-deck_width+deck_width/10, h/5+deck_height+h/50,0)
                Screen('DrawText', wPtr, 'Deck C', w/2+w/16+deck_width/10, h/5+deck_height+h/50,0)
                Screen('DrawText', wPtr, 'Deck D', w/2+3*w/16+deck_width+deck_width/10, h/5+deck_height+h/50,0)
                if net_change(deck_jump+1,1) > 1
                    Screen('DrawText', wPtr, net_income, w/2-w/16-deck_width-deck_width/4+deck_width/5-deck_width/10, h/5+deck_height+4*h/50,[0 255 0])
                else
                    Screen('DrawText', wPtr, net_income,w/2-w/16-deck_width-deck_width/4+deck_width/5-deck_width/10, h/5+deck_height+4*h/50,[255 0 0])
                end
                [nx, ny, bbox] = DrawFormattedText(wPtr,Current_total_show, 'center', 12*h/20, 0);
                [nx, ny, bbox] = DrawFormattedText(wPtr,Previous_total_show, 'center', 13*h/20, gray);
                Screen('DrawTexture', wPtr, t1, [], deck_A);
                Screen('DrawTexture', wPtr, t2, [], deck_B);
                Screen('DrawTexture', wPtr, t1, [], deck_C);
                Screen('DrawTexture', wPtr, t1, [], deck_D);
                Screen('Flip',wPtr);
                play_or_pass{deck_jump+1,1} = 'Play';
                dur_rt {deck_jump+1,1}= responseTime - startTime;
                WaitSecs(2);
                break;
            end
            
            if keycode_al(playkey) && isempty(c3)
                WaitSecs(0.1);
                net_change(deck_jump+1,1) = deck3_gains_a + deck3_losses_a (deck_jump,1);
                net_income = ['Amount $' num2str(net_change(deck_jump+1,1))];
                Current_total(deck_jump+1,1) = Current_total(deck_jump,1) + net_change(deck_jump+1,1);
                Previous_total (deck_jump+1,1)= Current_total(deck_jump+1,1) -  net_change(deck_jump+1,1);
                Current_total_show = ['Current total: $' num2str(Current_total(deck_jump+1,1))];
                Previous_total_show = ['Previous total: $' num2str(Previous_total (deck_jump+1,1))];
                Screen('TextFont',wPtr, 'Arial');
                Screen('TextSize',wPtr, 40);
                Screen('DrawText', wPtr, 'Play - A - Key', w/2-2*w/8, h/10,0)
                Screen('DrawText', wPtr, 'Pass - l - Key', w/2+w/10, h/10,0)
                Screen('TextFont',wPtr, 'Arial');
                Screen('TextSize',wPtr, 35);
                Screen('DrawText', wPtr, 'Deck A', w/2-3*w/16-2*deck_width+deck_width/10, h/5+deck_height+h/50,0)
                Screen('DrawText', wPtr, 'Deck B', w/2-w/16-deck_width+deck_width/10, h/5+deck_height+h/50,0)
                Screen('DrawText', wPtr, 'Deck C', w/2+w/16+deck_width/10, h/5+deck_height+h/50,0)
                Screen('DrawText', wPtr, 'Deck D', w/2+3*w/16+deck_width+deck_width/10, h/5+deck_height+h/50,0)
                if net_change(deck_jump+1,1) > 1
                    Screen('DrawText', wPtr, net_income,w/2+w/16-deck_width/4+deck_width/5-deck_width/10, h/5+deck_height+4*h/50,[0 255 0])
                else
                    Screen('DrawText', wPtr, net_income,w/2+w/16-deck_width/4+deck_width/5-deck_width/10, h/5+deck_height+4*h/50,[255 0 0])
                end
                [nx, ny, bbox] = DrawFormattedText(wPtr,Current_total_show, 'center', 12*h/20, 0);
                [nx, ny, bbox] = DrawFormattedText(wPtr,Previous_total_show, 'center', 13*h/20, gray);
                Screen('DrawTexture', wPtr, t1, [], deck_A);
                Screen('DrawTexture', wPtr, t1, [], deck_B);
                Screen('DrawTexture', wPtr, t2, [], deck_C);
                Screen('DrawTexture', wPtr, t1, [], deck_D);
                Screen('Flip',wPtr);
                play_or_pass{deck_jump+1,1} = 'Play';
                dur_rt {deck_jump+1,1}= responseTime - startTime;
                WaitSecs(2);
                break;
            end
            
            if  keycode_al(playkey) && isempty(c4)
                WaitSecs(0.1);
                net_change(deck_jump+1,1) = deck4_gains_a + deck4_losses_a (deck_jump,1);
                net_income = ['Amount $' num2str(net_change(deck_jump+1,1))];
                Current_total(deck_jump+1,1) = Current_total(deck_jump,1) + net_change(deck_jump+1,1);
                Previous_total (deck_jump+1,1)= Current_total(deck_jump+1,1) - net_change(deck_jump+1,1);
                Current_total_show = ['Current total: $' num2str(Current_total(deck_jump+1,1))];
                Previous_total_show = ['Previous total: $' num2str(Previous_total (deck_jump+1,1))];
                Screen('TextFont',wPtr, 'Arial');
                Screen('TextSize',wPtr, 40);
                Screen('DrawText', wPtr, 'Play - A - Key', w/2-2*w/8, h/10,0)
                Screen('DrawText', wPtr, 'Pass - l - Key', w/2+w/10, h/10,0)
                Screen('TextFont',wPtr, 'Arial');
                Screen('TextSize',wPtr, 35);
                Screen('DrawText', wPtr, 'Deck A', w/2-3*w/16-2*deck_width+deck_width/10, h/5+deck_height+h/50,0)
                Screen('DrawText', wPtr, 'Deck B', w/2-w/16-deck_width+deck_width/10, h/5+deck_height+h/50,0)
                Screen('DrawText', wPtr, 'Deck C', w/2+w/16+deck_width/10, h/5+deck_height+h/50,0)
                Screen('DrawText', wPtr, 'Deck D', w/2+3*w/16+deck_width+deck_width/10, h/5+deck_height+h/50,0)
                if net_change(deck_jump+1,1) > 1
                    Screen('DrawText', wPtr, net_income,w/2+3*w/16+deck_width-deck_width/4+deck_width/5-deck_width/10, h/5+deck_height+4*h/50,[0 255 0])
                else
                    Screen('DrawText', wPtr, net_income,w/2+3*w/16+deck_width-deck_width/4+deck_width/5-deck_width/10, h/5+deck_height+4*h/50,[255 0 0])
                end
                [nx, ny, bbox] = DrawFormattedText(wPtr,Current_total_show, 'center', 12*h/20, 0);
                [nx, ny, bbox] = DrawFormattedText(wPtr,Previous_total_show, 'center', 13*h/20, gray);
                Screen('DrawTexture', wPtr, t1, [], deck_A);
                Screen('DrawTexture', wPtr, t1, [], deck_B);
                Screen('DrawTexture', wPtr, t1, [], deck_C);
                Screen('DrawTexture', wPtr, t2, [], deck_D);
                Screen('Flip',wPtr);
                play_or_pass{deck_jump+1,1} = 'Play';
                dur_rt {deck_jump+1,1}= responseTime - startTime;
                WaitSecs(2);
                break;
            end
            
            if  keycode_al(passkey) && isempty(c1)
                WaitSecs(0.1);
                Current_total(deck_jump+1,1) = Current_total (deck_jump,1);
                Previous_total (deck_jump+1,1)= Previous_total (deck_jump,1);
                Current_total_show = ['Current total: $' num2str(Current_total(deck_jump+1,1))];
                Previous_total_show = ['Previous total: $' num2str(Previous_total (deck_jump+1,1))];
                Screen('TextFont',wPtr, 'Arial');
                Screen('TextSize',wPtr, 40);
                Screen('DrawText', wPtr, 'Play - A - Key', w/2-2*w/8, h/10,0);
                Screen('DrawText', wPtr, 'Pass - l - Key', w/2+w/10, h/10,0);
                Screen('TextFont',wPtr, 'Arial');
                Screen('TextSize',wPtr, 35);
                Screen('DrawText', wPtr, 'Deck A', w/2-3*w/16-2*deck_width+deck_width/10, h/5+deck_height+h/50,0);
                Screen('DrawText', wPtr, 'Deck B', w/2-w/16-deck_width+deck_width/10, h/5+deck_height+h/50,0);
                Screen('DrawText', wPtr, 'Deck C', w/2+w/16+deck_width/10, h/5+deck_height+h/50,0);
                Screen('DrawText', wPtr, 'Deck D', w/2+3*w/16+deck_width+deck_width/10, h/5+deck_height+h/50,0);
                Screen('DrawText', wPtr, 'PASS', w/2-3*w/16-2*deck_width+2*deck_width/10-deck_width/20, h/5+deck_height+4*h/50, [255 0 0]);
                [nx, ny, bbox] = DrawFormattedText(wPtr,Current_total_show, 'center', 12*h/20, 0);
                [nx, ny, bbox] = DrawFormattedText(wPtr,Previous_total_show, 'center', 13*h/20, gray);
                Screen('DrawTexture', wPtr, t2, [], deck_A);
                Screen('DrawTexture', wPtr, t1, [], deck_B);
                Screen('DrawTexture', wPtr, t1, [], deck_C);
                Screen('DrawTexture', wPtr, t1, [], deck_D);
                Screen('Flip',wPtr);
                play_or_pass{deck_jump+1,1} = 'Pass';
                dur_rt {deck_jump+1,1}= responseTime - startTime;
                WaitSecs(2);
                break;
            end
            
            if keycode_al(passkey) && isempty(c2)
                WaitSecs(0.1);
                Current_total(deck_jump+1,1) = Current_total(deck_jump,1);
                Previous_total (deck_jump+1,1)= Previous_total (deck_jump,1);
                Current_total_show = ['Current total: $' num2str(Current_total(deck_jump+1,1))];
                Previous_total_show = ['Previous total: $' num2str(Previous_total (deck_jump+1,1))];
                Screen('TextFont',wPtr, 'Arial');
                Screen('TextSize',wPtr, 40);
                Screen('DrawText', wPtr, 'Play - A - Key', w/2-2*w/8, h/10,0);
                Screen('DrawText', wPtr, 'Pass - l - Key', w/2+w/10, h/10,0);
                Screen('TextFont',wPtr, 'Arial');
                Screen('TextSize',wPtr, 35);
                Screen('DrawText', wPtr, 'Deck A', w/2-3*w/16-2*deck_width+deck_width/10, h/5+deck_height+h/50,0);
                Screen('DrawText', wPtr, 'Deck B', w/2-w/16-deck_width+deck_width/10, h/5+deck_height+h/50,0);
                Screen('DrawText', wPtr, 'Deck C', w/2+w/16+deck_width/10, h/5+deck_height+h/50,0);
                Screen('DrawText', wPtr, 'Deck D', w/2+3*w/16+deck_width+deck_width/10, h/5+deck_height+h/50,0);
                Screen('DrawText', wPtr, 'PASS', w/2-w/16-deck_width+2*deck_width/10-deck_width/20, h/5+deck_height+4*h/50,[255 0 0]);
                [nx, ny, bbox] = DrawFormattedText(wPtr,Current_total_show, 'center', 12*h/20, 0);
                [nx, ny, bbox] = DrawFormattedText(wPtr,Previous_total_show, 'center', 13*h/20, gray);
                Screen('DrawTexture', wPtr, t1, [], deck_A);
                Screen('DrawTexture', wPtr, t2, [], deck_B);
                Screen('DrawTexture', wPtr, t1, [], deck_C);
                Screen('DrawTexture', wPtr, t1, [], deck_D);
                Screen('Flip',wPtr);
                play_or_pass{deck_jump+1,1} = 'Pass';
                dur_rt {deck_jump+1,1}= responseTime - startTime;
                WaitSecs(2);
                break;
            end
            
            if keycode_al(passkey) && isempty(c3)
                WaitSecs(0.1);
                Current_total(deck_jump+1,1) = Current_total(deck_jump,1);
                Previous_total (deck_jump+1,1)= Previous_total (deck_jump,1);
                Current_total_show = ['Current total: $' num2str(Current_total(deck_jump+1,1))];
                Previous_total_show = ['Previous total: $' num2str(Previous_total (deck_jump+1,1))];
                Screen('TextFont',wPtr, 'Arial');
                Screen('TextSize',wPtr, 40);
                Screen('DrawText', wPtr, 'Play - A - Key', w/2-2*w/8, h/10,0);
                Screen('DrawText', wPtr, 'Pass - l - Key', w/2+w/10, h/10,0);
                Screen('TextFont',wPtr, 'Arial');
                Screen('TextSize',wPtr, 35);
                Screen('DrawText', wPtr, 'Deck A', w/2-3*w/16-2*deck_width+deck_width/10, h/5+deck_height+h/50,0);
                Screen('DrawText', wPtr, 'Deck B', w/2-w/16-deck_width+deck_width/10, h/5+deck_height+h/50,0);
                Screen('DrawText', wPtr, 'Deck C', w/2+w/16+deck_width/10, h/5+deck_height+h/50,0);
                Screen('DrawText', wPtr, 'Deck D', w/2+3*w/16+deck_width+deck_width/10, h/5+deck_height+h/50,0);
                Screen('DrawText', wPtr, 'PASS', w/2+w/16+2*deck_width/10-deck_width/20, h/5+deck_height+4*h/50,[255 0 0]);
                [nx, ny, bbox] = DrawFormattedText(wPtr,Current_total_show, 'center', 12*h/20, 0);
                [nx, ny, bbox] = DrawFormattedText(wPtr,Previous_total_show, 'center', 13*h/20, gray);
                Screen('DrawTexture', wPtr, t1, [], deck_A);
                Screen('DrawTexture', wPtr, t1, [], deck_B);
                Screen('DrawTexture', wPtr, t2, [], deck_C);
                Screen('DrawTexture', wPtr, t1, [], deck_D);
                Screen('Flip',wPtr);
                play_or_pass{deck_jump+1,1} = 'Pass';
                dur_rt {deck_jump+1,1}= responseTime - startTime;
                WaitSecs(2);
                break;
            end
            
            if  keycode_al(passkey) && isempty(c4)
                WaitSecs(0.1);
                Current_total(deck_jump+1,1) = Current_total(deck_jump,1);
                Previous_total (deck_jump+1,1)= Previous_total (deck_jump,1);
                Current_total_show = ['Current total: $' num2str(Current_total(deck_jump+1,1))];
                Previous_total_show = ['Previous total: $' num2str(Previous_total (deck_jump+1,1))];
                Screen('TextFont',wPtr, 'Arial');
                Screen('TextSize',wPtr, 40);
                Screen('DrawText', wPtr, 'Play - A - Key', w/2-2*w/8, h/10,0);
                Screen('DrawText', wPtr, 'Pass - l - Key', w/2+w/10, h/10,0);
                Screen('TextFont',wPtr, 'Arial');
                Screen('TextSize',wPtr, 35);
                Screen('DrawText', wPtr, 'Deck A', w/2-3*w/16-2*deck_width+deck_width/10, h/5+deck_height+h/50,0);
                Screen('DrawText', wPtr, 'Deck B', w/2-w/16-deck_width+deck_width/10, h/5+deck_height+h/50,0);
                Screen('DrawText', wPtr, 'Deck C', w/2+w/16+deck_width/10, h/5+deck_height+h/50,0);
                Screen('DrawText', wPtr, 'Deck D', w/2+3*w/16+deck_width+deck_width/10, h/5+deck_height+h/50,0);
                Screen('DrawText', wPtr, 'PASS', w/2+3*w/16+deck_width+2*deck_width/10-deck_width/20, h/5+deck_height+4*h/50,[255 0 0]);
                [nx, ny, bbox] = DrawFormattedText(wPtr,Current_total_show, 'center', 12*h/20, 0);
                [nx, ny, bbox] = DrawFormattedText(wPtr,Previous_total_show, 'center', 13*h/20, gray);
                Screen('DrawTexture', wPtr, t1, [], deck_A);
                Screen('DrawTexture', wPtr, t1, [], deck_B);
                Screen('DrawTexture', wPtr, t1, [], deck_C);
                Screen('DrawTexture', wPtr, t2, [], deck_D);
                Screen('Flip',wPtr);
                play_or_pass{deck_jump+1,1} = 'Pass';
                dur_rt {deck_jump+1,1}= responseTime - startTime;
                WaitSecs(2);
                break;
            end
            
        end % if ~isempty (key_selected)
    end % while getsecs - starttime < 4
    
    
    % if no key is pressed during 4s
    
    if  ~keycode_al(playkey) && ~keycode_al(passkey) && isempty(c1)
        WaitSecs(0.1);
        Current_total(deck_jump+1,1) = Current_total(deck_jump,1);
        Previous_total (deck_jump+1,1)= Previous_total (deck_jump,1);
        Current_total_show = ['Current total: $' num2str(Current_total(deck_jump+1,1))];
        Previous_total_show = ['Previous total: $' num2str(Previous_total (deck_jump+1,1))];
        Screen('TextFont',wPtr, 'Arial');
        Screen('TextSize',wPtr, 40);
        Screen('DrawText', wPtr, 'Play - A - Key', w/2-2*w/8, h/10,0);
        Screen('DrawText', wPtr, 'Pass - l - Key', w/2+w/10, h/10,0);
        Screen('TextFont',wPtr, 'Arial');
        Screen('TextSize',wPtr, 35);
        Screen('DrawText', wPtr, 'Deck A', w/2-3*w/16-2*deck_width+deck_width/10, h/5+deck_height+h/50,0);
        Screen('DrawText', wPtr, 'Deck B', w/2-w/16-deck_width+deck_width/10, h/5+deck_height+h/50,0);
        Screen('DrawText', wPtr, 'Deck C', w/2+w/16+deck_width/10, h/5+deck_height+h/50,0);
        Screen('DrawText', wPtr, 'Deck D', w/2+3*w/16+deck_width+deck_width/10, h/5+deck_height+h/50,0);
        Screen('DrawText', wPtr, 'PASS', w/2-3*w/16-2*deck_width+2*deck_width/10-deck_width/20, h/5+deck_height+4*h/50, [255 0 0]);
        [nx, ny, bbox] = DrawFormattedText(wPtr,Current_total_show, 'center', 12*h/20, 0);
        [nx, ny, bbox] = DrawFormattedText(wPtr,Previous_total_show, 'center', 13*h/20, gray);
        Screen('DrawTexture', wPtr, t2, [], deck_A);
        Screen('DrawTexture', wPtr, t1, [], deck_B);
        Screen('DrawTexture', wPtr, t1, [], deck_C);
        Screen('DrawTexture', wPtr, t1, [], deck_D);
        Screen('Flip',wPtr);
        play_or_pass{deck_jump+1,1} = 'N/A';
        dur_rt {deck_jump+1,1}= 'N/A';
        WaitSecs(2);
        
    elseif  ~keycode_al(playkey) && ~ keycode_al(passkey) && isempty(c2)
        WaitSecs(0.1);
        Current_total(deck_jump+1,1) = Current_total(deck_jump,1);
        Previous_total (deck_jump+1,1)= Previous_total (deck_jump,1);
        Current_total_show = ['Current total: $' num2str(Current_total(deck_jump+1,1))];
        Previous_total_show = ['Previous total: $' num2str(Previous_total (deck_jump+1,1))];
        Screen('TextFont',wPtr, 'Arial');
        Screen('TextSize',wPtr, 40);
        Screen('DrawText', wPtr, 'Play - A - Key', w/2-2*w/8, h/10,0);
        Screen('DrawText', wPtr, 'Pass - l - Key', w/2+w/10, h/10,0);
        Screen('TextFont',wPtr, 'Arial');
        Screen('TextSize',wPtr, 35);
        Screen('DrawText', wPtr, 'Deck A', w/2-3*w/16-2*deck_width+deck_width/10, h/5+deck_height+h/50,0);
        Screen('DrawText', wPtr, 'Deck B', w/2-w/16-deck_width+deck_width/10, h/5+deck_height+h/50,0);
        Screen('DrawText', wPtr, 'Deck C', w/2+w/16+deck_width/10, h/5+deck_height+h/50,0);
        Screen('DrawText', wPtr, 'Deck D', w/2+3*w/16+deck_width+deck_width/10, h/5+deck_height+h/50,0);
        Screen('DrawText', wPtr, 'PASS', w/2-w/16-deck_width+2*deck_width/10-deck_width/20, h/5+deck_height+4*h/50,[255 0 0]);
        [nx, ny, bbox] = DrawFormattedText(wPtr,Current_total_show, 'center', 12*h/20, 0);
        [nx, ny, bbox] = DrawFormattedText(wPtr,Previous_total_show, 'center', 13*h/20, gray);
        Screen('DrawTexture', wPtr, t1, [], deck_A);
        Screen('DrawTexture', wPtr, t2, [], deck_B);
        Screen('DrawTexture', wPtr, t1, [], deck_C);
        Screen('DrawTexture', wPtr, t1, [], deck_D);
        Screen('Flip',wPtr);
        play_or_pass{deck_jump+1,1} = 'N/A';
        dur_rt {deck_jump+1,1}= 'N/A';
        WaitSecs(2);
        
    elseif  ~keycode_al(playkey) && ~ keycode_al(passkey) && isempty(c3)
        WaitSecs(0.1);
        Current_total(deck_jump+1,1) = Current_total(deck_jump,1);
        Previous_total (deck_jump+1,1)= Previous_total (deck_jump,1);
        Current_total_show = ['Current total: $' num2str(Current_total(deck_jump+1,1))];
        Previous_total_show = ['Previous total: $' num2str(Previous_total (deck_jump+1,1))];
        Screen('TextFont',wPtr, 'Arial');
        Screen('TextSize',wPtr, 40);
        Screen('DrawText', wPtr, 'Play - A - Key', w/2-2*w/8, h/10,0);
        Screen('DrawText', wPtr, 'Pass - l - Key', w/2+w/10, h/10,0);
        Screen('TextFont',wPtr, 'Arial');
        Screen('TextSize',wPtr, 35);
        Screen('DrawText', wPtr, 'Deck A', w/2-3*w/16-2*deck_width+deck_width/10, h/5+deck_height+h/50,0);
        Screen('DrawText', wPtr, 'Deck B', w/2-w/16-deck_width+deck_width/10, h/5+deck_height+h/50,0);
        Screen('DrawText', wPtr, 'Deck C', w/2+w/16+deck_width/10, h/5+deck_height+h/50,0);
        Screen('DrawText', wPtr, 'Deck D', w/2+3*w/16+deck_width+deck_width/10, h/5+deck_height+h/50,0);
        Screen('DrawText', wPtr, 'PASS', w/2+w/16+2*deck_width/10-deck_width/20, h/5+deck_height+4*h/50,[255 0 0]);
        [nx, ny, bbox] = DrawFormattedText(wPtr,Current_total_show, 'center', 12*h/20, 0);
        [nx, ny, bbox] = DrawFormattedText(wPtr,Previous_total_show, 'center', 13*h/20, gray);
        Screen('DrawTexture', wPtr, t1, [], deck_A);
        Screen('DrawTexture', wPtr, t1, [], deck_B);
        Screen('DrawTexture', wPtr, t2, [], deck_C);
        Screen('DrawTexture', wPtr, t1, [], deck_D);
        Screen('Flip',wPtr);
        play_or_pass{deck_jump+1,1} = 'N/A';
        dur_rt {deck_jump+1,1}= 'N/A';
        WaitSecs(2);
        
    elseif  ~keycode_al(playkey) && ~ keycode_al(passkey) && isempty(c4)
        WaitSecs(0.1);
        Current_total(deck_jump+1,1) = Current_total(deck_jump,1);
        Previous_total (deck_jump+1,1)= Previous_total (deck_jump,1);
        Current_total_show = ['Current total: $' num2str(Current_total(deck_jump+1,1))];
        Previous_total_show = ['Previous total: $' num2str(Previous_total (deck_jump+1,1))];
        Screen('TextFont',wPtr, 'Arial');
        Screen('TextSize',wPtr, 40);
        Screen('DrawText', wPtr, 'Play - A - Key', w/2-2*w/8, h/10,0);
        Screen('DrawText', wPtr, 'Pass - l - Key', w/2+w/10, h/10,0);
        Screen('TextFont',wPtr, 'Arial');
        Screen('TextSize',wPtr, 35);
        Screen('DrawText', wPtr, 'Deck A', w/2-3*w/16-2*deck_width+deck_width/10, h/5+deck_height+h/50,0);
        Screen('DrawText', wPtr, 'Deck B', w/2-w/16-deck_width+deck_width/10, h/5+deck_height+h/50,0);
        Screen('DrawText', wPtr, 'Deck C', w/2+w/16+deck_width/10, h/5+deck_height+h/50,0);
        Screen('DrawText', wPtr, 'Deck D', w/2+3*w/16+deck_width+deck_width/10, h/5+deck_height+h/50,0);
        Screen('DrawText', wPtr, 'PASS', w/2+3*w/16+deck_width+2*deck_width/10-deck_width/20, h/5+deck_height+4*h/50,[255 0 0]);
        [nx, ny, bbox] = DrawFormattedText(wPtr,Current_total_show, 'center', 12*h/20, 0);
        [nx, ny, bbox] = DrawFormattedText(wPtr,Previous_total_show, 'center', 13*h/20, gray);
        Screen('DrawTexture', wPtr, t1, [], deck_A);
        Screen('DrawTexture', wPtr, t1, [], deck_B);
        Screen('DrawTexture', wPtr, t1, [], deck_C);
        Screen('DrawTexture', wPtr, t2, [], deck_D);
        Screen('Flip',wPtr);
        play_or_pass{deck_jump+1,1} = 'N/A';
        dur_rt {deck_jump+1,1}= 'N/A';
        WaitSecs(2);
    end
    
end %for jump 1:120

%-----------------------------------------------------------------------------------------------
%  end of trial, end of trial, end of trial, end of trial, end of trial, end of trial
%-----------------------------------------------------------------------------------------------

printed_result = horzcat(randDeck, net_change, Current_total,Previous_total);
printed_result_4 = cellfun(@num2str, num2cell(printed_result), 'UniformOutput', false);
printed_result_5 = horzcat(printed_result_4, play_or_pass, dur_rt);
header = {'randDeck', 'net_change', 'Current_totala', 'Previous_total', 'Play or Pass', 'Reaction_time'};
fin_printed_result = [header; printed_result_5];
folder = './result';
save([folder '/result_' num2str(subject_ID) '.mat'], 'fin_printed_result');

Screen(wPtr,'Close');
close all
return;
end

