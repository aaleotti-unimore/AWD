%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sistema=Analizza_il_Sistema(Sistema)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear global 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
System_Variables = {...
'Show_Schema_In','No', ...
'Show_Schema_In_Senza_Apici','Si', ...
'Show_Schema_ASCII','Si', ...
'Show_ASCII_Latex','Si', ...
'Crea_Files_CSV','No', ...
 };
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin==0; 
    Sistema=''; disp(' ')
    disp('Non � stato fornito nessun argomento')
    return
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Se viene fornito un file legge lo schema dal file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(Sistema)                  % Se Sistema � una strina ...
    Ind=strfind(Sistema,'/');       % si cercano i caratteri '/'
    if not(isempty(Ind))
        Sistema=[ '.\media\' strrep(Sistema,'/','\')]; % ... e si sostituiscono con '\'
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% I SEGUENTI COMANDI FACILITANO L'UTENTE E POSSONO ESSERE CAMBIATI
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Schema_In={'**, GTy,png, pGTy,png, xPr,Si, sPr,Si'};
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% VENGONO LETTI I COMANDI DEFINITI DALL'UTENTE    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Sistema=LEGGI_SCHEMA_DA_FILE(Sistema,Schema_In);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% I SEGUENTI COMANDI IMPONGONO ALCUNI VINCOLI SULL'UTILIZZO DEL PROGRAMMA 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Sistema.Schema_In(end-1)={'**, Pr,Si, SIM, No'};                       
    Sistema.Schema_In(end) ={'**, pPr,Si'};                                
else
    Sistema.Dir_out='.\';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Definisce le variabili di sistema contenute in "System_Variables"
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii=1:2:length(System_Variables)
    eval(['Sistema.' System_Variables{ii} '=''' System_Variables{ii+1} ''';'])
end
%%%% Aggiunge le strutture di base alla variabile "Sistema"
Sistema = ADD_THE_BASIC_STRUCTURES(Sistema);
%%%% Se lo "Schema_In" � vuoto si procede a crearlo graficamente
if isempty(Sistema.Schema_In)
    % Costruisci  lo schema
    disp(' '); disp('Lo Schema fornito NON � corretto: � vuoto'); disp(' ')
end
try
    %%%% Se lo "Schema_In" non � vuoto si procede ad analizzarlo
    if not(isempty(Sistema))
        Sistema = CREA_LO_SCHEMA(Sistema);
        if strcmp(Sistema.Genera_il_file_diary,'Si')
            diary([Sistema.Dir_out Sistema.Title '_diary.txt'])        % Attiva il diary
        end        
        if strcmp(Sistema.Analizza_lo_Schema,'Si')&&strcmp(Sistema.Domini_Omogenei,'Si')
            Sistema = EQUAZIONI_NELLO_SPAZIO_DEGLI_STATI(Sistema);
        end
        if strcmp(Sistema.Grafico.Show_Grafico,'Si')
            Sistema = DISEGNA_LO_SCHEMA(Sistema);
        end
        if strcmp(Sistema.Schema_Analizzato,'Si')&&strcmp(Sistema.Crea_lo_Schema_POG,'Si')
            Sistema = SHOW_SCHEMA_A_BLOCCHI_POG(Sistema);
        end
        if strcmp(Sistema.Schema_POG_Generato,'Si')&&strcmp(Sistema.Crea_lo_Schema_SLX,'Si')
            Sistema = CREA_LO_SCHEMA_SIMULINK(Sistema);
        end
        if strcmp(Sistema.Schema_SLX_Generato,'Si')&&strcmp(Sistema.Simula_lo_Schema_SLX,'Si')
            Sistema = SIMULA_LO_SCHEMA_SIMULINK(Sistema);
        end
    end
catch My_Err
    Sistema.My_Err=My_Err;
    getReport(My_Err)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Sistema.Genera_il_file_diary,'Si')
    diary off        % Disattiva il diary
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Dir_out=Sistema.Dir_out;
% movefile('diary.txt',[Dir_out Sistema.Grafico.Nome_del_grafico '_diary.txt'])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Il file ".done" e il file "*.zip" vengono creati solo se "Dir_out"~='.\'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if not(strcmp(Dir_out,'.\'))
    delete([Dir_out '*.zip'])                               % Cancella il file zip nel direttorio corrente
%     Zip_Files=dir(Dir_out);
%     for ii=1:length(Zip_Files)
%         File_ii=Zip_Files(ii).name;
%         if not(strcmp(File_ii(1),'.'))
%             zip([Dir_out Sistema.Title],{[Dir_out File_ii]})    %
%         end
%     end
%      zip([Dir_out Sistema.Title],{[Dir_out '..\*.txt']})    %
    zip([Dir_out '..\' Sistema.Title],{[Dir_out '..\*.txt'],[Dir_out '*.*']})    %
    movefile([Dir_out '..\*.zip'],Dir_out)
    FID=fopen([Dir_out '.done'],'w');
    fclose(FID);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Sistema = ADD_THE_BASIC_STRUCTURES(Sistema)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Per tutti i generatori la potenza � uscente dal blocco: Pow_In=-1.
%%% Per tutti gli altri blocchi la potenza � entrante nel blocco Pow_In=1
%%% Per cambiare la direzione positiva della potenza usare il comando 'Pin,1/2'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% VARIABILI PREDEFINTE PER CIASCUN BLOCCO FISICO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sistema.Indice_B={'Sigla', 'Tipo_di_Ramo', 'Diretto', 'Out', 'E_name', 'K_name', 'Q_name', 'F_name', 'Show_It', 'Help', 'Comandi', 'Help_ENG', 'E_Str', 'K_Str', 'Q_Str', 'F_Str'};
Sistema.Parms_Blocchi={...
    {'|>','Filo'      ,'Si','Flow'  ,'E','K','Q','F','No','Freccia corrente','Zoom=10;','Current arrow','','','',''},...
    {'|^','Filo'      ,'Si','Flow'  ,'E','K','Q','F','No','Freccia di tensione','Zoom=10;','Voltage arrow','','','',''},...
    {'::','Filo'      ,'Si','Flow'  ,'E','K','Q','F','No','Tratteggio','Zoom=10; Line_Width=0.3; Line_Type=''--k'';','Dashed line','','','',''},...
    {'^>','Filo'      ,'Si','Flow'  ,'E','K','Q','F','No','Freccie di tensione e corrente','Zoom=10;','Voltage and current arrows','','','',''},...
    {':^','Filo'      ,'Si','Flow'  ,'E','K','Q','F','No','Tratteggio con frecce','Zoom=10; Line_Width=0.3; Line_Type=''--k'';','Dashed line with arrows','','','',''},...
    {'--','Filo'      ,'Si','Effort','E','K','Q','F','No','Filo','','Wire','','','',''},...
    {'-D','Filo'      ,'Si','Flow'  ,'E','K','Q','F','No','Blocco Diodo','','Diode block','','','',''},...
    {'-/','Filo'      ,'Si','Flow'  ,'E','K','Q','F','No','Blocco Switch','','Switch block','','','',''},...
    {'eU','Ingresso'  ,'Si','Vuoto' ,'V','K','Q','I','No','Ingresso elettrico non orientato','Pow_In=-1;','Non-oriented electric Input','Voltage','Parameter','','Current'},...
    {'eC','Dinamico'  ,'Si','Effort','V','C','Q','I','Si','Condensatore elettrico','','Electric Capacitor','Voltage','Capacitance','Charge','Current'},...
    {'eL','Dinamico'  ,'Si','Flow'  ,'V','L','F','I','Si','Induttanza elettrica','','Electric Inductor','Voltage','Inductance','Flux','Current'},...
    {'eR','Resistivo' ,'Si','Vuoto' ,'V','R','Q','I','Si','Resistenza elettrica','','Electric Resistance','Voltage','Resistance','','Current'},...
    {'eG','Resistivo' ,'No','Vuoto' ,'I','G','Q','V','Si','Conduttanza eletrica','','Electric Conductance','Voltage','Conductance','','Current'},...
    {'mU','Ingresso'  ,'Si','Vuoto' ,'v','K','Q','F','No','Ingresso T-Meccanico non orientato','Pow_In=-1;','Non-oriented T-Mechanical Input','Velocity','Parameter','','Force'},...
    {'mM','Dinamico'  ,'Si','Effort','v','M','P','F','Si','Massa traslazionale','','Translational Mass','Velocity','Mass','Momentum','Force'},...
    {'mE','Dinamico'  ,'Si','Flow'  ,'v','E','x','F','Si','Elasticita'' traslazionale','','Translational Elasticity','Velocity','Elasticity','Displacement','Force'},...
    {'mK','Dinamico'  ,'No','Flow'  ,'v','K','x','F','Si','Rigidita'' traslazionale','','Translational Stiffness','Velocity','Stiffness','Displacement','Force'},...
    {'mD','Resistivo' ,'Si','Vuoto' ,'v','d','Q','F','Si','Reciproco del coefficiente d''attrito','','Reciprocal of the friction coefficient','Velocity','Co-Friction','','Force'},...
    {'mB','Resistivo' ,'No','Vuoto' ,'v','b','Q','F','Si','Coefficiente d''attrito','','Friction coefficient','Velocity','Friction','','Force'},...
    {'rU','Ingresso'  ,'Si','Vuoto' ,'w','K','Q','T','No','Ingresso R-Meccanico non orientato','Pow_In=-1;','Non-oriented T-Mechanical Input','Ang. Velocity','Parameter','','Torque'},...
    {'rJ','Dinamico'  ,'Si','Effort','w','J','P','T','Si','Inerzia rotazionale','','Rotational Inertia','Ang. Velocity','Inertia','Angular momentum','Torque'},...
    {'rE','Dinamico'  ,'Si','Flow'  ,'w','E','t','T','Si','Elasticita'' rotazionale','','Rotational Elasticity','Ang. Velocity','Angular elesticity','Angular displacement','Torque'},...
    {'rK','Dinamico'  ,'No','Flow'  ,'w','K','t','T','Si','Rigidita'' rotazionale','','Rotational Stiffness','Ang. Velocity','Angular stiffness','Angular displacement','Torque'},...
    {'rD','Resistivo' ,'Si','Vuoto' ,'w','d','Q','T','Si','Reciproco del coefficiente d''attrito rotazionale','','Reciprocal of rotational friction coefficient','Angular velocity','Angular co-friction','','Torque'},...
    {'rB','Resistivo' ,'No','Vuoto' ,'w','b','Q','T','Si','Coefficiente d''attrito rotazionale','','rotational friction coefficient','Angular velocity','Angular friction','','Torque'},...
    {'iU','Ingresso'  ,'Si','Vuoto' ,'P','K','Q','Q','No','Ingresso idraulico non orientato','Pow_In=-1;','Non-oriented hydraulic Input','Pressure','Parameter','','Volume Flow rate'},...
    {'iC','Dinamico'  ,'Si','Effort','P','C','V','Q','Si','Capacita'' Idraulica','','Hydraulic Capacitor','Pressure','Hyd. Capacitance','Volume','Volume Flow rate'},...
    {'iK','Dinamico'  ,'No','Effort','P','C','V','Q','Si','Rigidita'' Idraulica','','Hydraulic Stiffness','Pressure','Hyd. Stiffness','Volume','Volume Flow rate'},...
    {'iL','Dinamico'  ,'Si','Flow'  ,'P','L','F','Q','Si','Induttanza Idraulica','','Hydraulic Inductor','Pressure','Hyd. Inductance','Hyd. Flux','Volume Flow rate'},...
    {'iR','Resistivo' ,'Si','Vuoto' ,'P','R','Q','Q','Si','Resistenza Idraulica','','Hydraulic Resistance','Pressure','Hyd. Resistance','','Volume Flow rate'},...
    {'iG','Resistivo' ,'No','Vuoto' ,'P','G','Q','Q','Si','Conduttanza Idraulica','','Hydraulic Conductance','Pressure','Hyd. Conductance','','Volume Flow rate'},...
    };
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sistema.Parms_Meta_Blocchi={...
    {'eV','Ingresso'  ,'Si','Effort','V','Z','Q','I','Si','Generarore di Tensione','Pow_In=-1;','Voltage generator','Voltage','Parameter','','Current'},...
    {'eI','Ingresso'  ,'Si','Flow'  ,'I','Z','Q','V','Si','Generatore di Corrente','X_up_down=1;Pow_In=-1;','Current generator','Voltage','Parameter','','Current'},...
    {'mV','Ingresso'  ,'Si','Effort','v','Z','Q','F','Si','Generarore di Velocita''','Pow_In=-1;','Velocity generator','Velocity','Parameter','','Force'},...
    {'mF','Ingresso'  ,'Si','Flow'  ,'F','Z','Q','v','Si','Generatore di Forza','Pow_In=-1;','Force generator','Velocity','Parameter','','Force'},...
    {'rW','Ingresso'  ,'Si','Effort','W','Z','Q','T','Si','Generarore di velocita'' angolare','Pow_In=-1;','Angular velocity generator','Angular velocity','Parameter','','Torque'},...
    {'rT','Ingresso'  ,'Si','Flow'  ,'T','Z','Q','W','Si','Generatore di Coppia','Pow_In=-1;','Torque generator','Angular velocity','Parameter','','Torque'},...
    {'iP','Ingresso'  ,'Si','Effort','P','Z','Q','Q','Si','Generarore di Pressione','Pow_In=-1;','Pressure generator','Pressure','Parameter','','Volume Flow rate'},...
    {'iQ','Ingresso'  ,'Si','Flow'  ,'Q','Z','Q','P','Si','Generatore di Portata Volumetrica','Pow_In=-1;','Volume flow rate generator','Pressure','Parameter','','Volume Flow rate'},...
    };
% Parametri_Meta_Blocchi = COSTRUISCI_LA_STRUTTURA(Sistema.Parms_Meta_Blocchi,Sistema.Indice_B); % NON VIENE USATA 
%     {'||','Filo','Flow','_','a','_','','Blocco filo di tipo: ramo aperto (Out=Flow; MEGLIO NON USARLO)'},...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% VARIABILI DI RAMO MODIFICABILI DALL'UTENTE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sistema.Indice_R={'Nome', 'Value', 'Sigla', 'StrNum', 'Vincoli', 'Range_and_Set', 'Type', 'Show_It', 'Help', 'Help_ENG'};
Sistema.Parms_Rami={...
    ... %-- Parametri POG che si applicano a tutti i Rami  -----------------------------------------%
    {'pog_Block_S_dx'     ,'[]','pSx' ,'Num','','','POG','Si','Larghezza del blocco integratore S','Width of the integral block S'},...
    {'pog_Block_S_dy'     ,'[]','pSy' ,'Num','','','POG','Si','Altezza del blocco integratore S','Height of the integral block S'},...
    {'pog_Block_M_dx'     ,'[]','pMx' ,'Num','','','POG','Si','Larghezza del blocco proporzionale M','Width of the proportional block M'},...
    {'pog_Block_M_dy'     ,'[]','pMy' ,'Num','','','POG','Si','Altezza del blocco proporzionale M','Height  of the proportional block M'},...
    {'pog_From_S_to_M_dy' ,'[]','pSyM','Num','','','POG','Si','Distanza tra blocco integratore S e blocco proporzionale M','Distance between the integral block S and the proportional block M'},...
    {'pog_Space_dx'       ,'[]','pSpx','Num','','','POG','Si','Spazio libero intorno al blocco','Free space within the block'},...
    {'pog_S_exists'       ,'[]','pSsi','Str','','','POG','No','Indica se e" presente il blocco integratore','Indicates if the integration block is present'},...
    {'pog_Effort_Su'      ,'[]','pEsu','Str','','','POG','Si','Indica se la variabile Efford e" posta in alto','Indicates if the effor variable En is up-located'},...
    {'pog_Vai_a_Destra'   ,'[]','pDst','Str','','','POG','No','Indica se lo sviluppo dello schema e" verso destra','Indicates if the POG block scheme must be developed left or right'},...
    {'pog_Line_Width'     ,'[]','pLw' ,'Num','','','POG','Si','Larghezza della linea del ramo POG','Line width of the POG branch'},...
    {'pog_Line_Type'      ,'[]','pLt' ,'Str','','','POG','Si','Tipo di tratteggio e il colore delle linee del ramo POG','Hatch type and color of the lines of the POG branch'},...
    {'pog_Show_Y'         ,'[]','pShY','Str','','','POG','Si','Indica se visualizzare la variabile di ingresso Y','Indicates if the input variable Y must be visualized'},...
    {'pog_Font_Y'         ,'[]','pFnY','Num','','','POG','Si','Dimensione del font della variabile di ingresso Y','Font dimension of the input variable Y'},...
    {'pog_Color_Y'        ,'[]','pClY','Str','','','POG','Si','Colore della variabile di ingresso Y','Color of the input variable Y'},...
    {'pog_Show_Q'         ,'[]','pShQ','Str','','','POG','Si','Indica se visualizzare la variabile energia Q','Indicates if the energy variable Q must be visualized'},...
    {'pog_Font_Q'         ,'[]','pFnQ','Num','','','POG','Si','Dimensione del font della variabile energia Q','Font dimension of the energy variable Q'},...
    {'pog_Color_Q'        ,'[]','pClQ','Str','','','POG','Si','Colore dela variabile energia Q','Color of the energy variable Q'},...
    {'pog_Show_K'         ,'[]','pShK','Str','','','POG','Si','Indica se visualizzare il parametro interno K','Indicates if the internal parameter K must be visualized'},...
    {'pog_Font_K'         ,'[]','pFnK','Num','','','POG','Si','Dimensione del font del parametro interno K','Font dimension of the internal parameter K'},...
    {'pog_Color_K'        ,'[]','pClK','Str','','','POG','Si','Colore del parametro interno K','Color of the internal parameter K'},...
    {'pog_Show_X'         ,'[]','pShX','Str','','','POG','Si','Indica se visualizzare la variabile di uscita X','Indicates if the output variable X must be visualized'},...
    {'pog_Font_X'         ,'[]','pFnX','Num','','','POG','Si','Dimensione del font della variabile di uscita X','Font dimension of the output variable X'},...
    {'pog_Color_X'        ,'[]','pClX','Str','','','POG','Si','Colore della variabile di uscita X','Color of the output variable X'},...
    {'pog_Show_T'         ,'[]','pShT','Str','','','POG','Si','Indica se visualizzare il tratteggio','Indicates if the dashed line must be visualized'},...
    {'pog_Width_T'        ,'[]','pLwT','Num','','','POG','Si','Spessore della linea di tratteggio','Width of the dashed line'},...
    {'pog_Color_T'        ,'[]','pClT','Str','','','POG','Si','Colore della linea di tratteggio','Color of the dashed line'},...
    {'pog_Visibile'       ,'[]','pVs' ,'Str','','','POG','Si','Indica se il ramo POG deve essere visualizzato o no','Indicates if the POG branch must be visualized'},...
    {'pog_Show_Nome_Ramo' ,'[]','pSr' ,'Str','','','POG','Si','Indica se visualizzare il nome numerico del ramo POG','Indicates if the numeric name of the POG branch must be visualized'},...
    {'pog_Font_Nome_Ramo' ,'[]','pFr' ,'Num','','','POG','Si','Dimensione del font del nome numerico del ramo POG','Font dimension of the numeric name of the POG branch'},...
    {'pog_Color_Nome_Ramo','[]','pCr' ,'Str','','','POG','Si','Colore del nome numerico del ramo POG','Color of the numeric name of the POG branch'},...
    {'pog_Colored'    ,'[]','pColored','Str','','','POG','Si','Indica se il ramo POG deve essere colorato o meno','Indicates if the POG branch must be colored'},...
    {'pog_Color_e'        ,'[]','pCle','Num','','','POG','Si','Colore RGB dei rami POG di natura elettro-magnetica','RGB color of the electromagnetic POG branches'},...
    {'pog_Color_m'        ,'[]','pClm','Num','','','POG','Si','Colore RGB dei rami POG di natura meccanico-traslazionale','RGB color of the mechanical-translational POG branches'},...
    {'pog_Color_r'        ,'[]','pClr','Num','','','POG','Si','Colore RGB dei rami POG di natura meccanico-rotazionale','RGB color of the mechanical-rotational POG branches'},...
    {'pog_Color_i'        ,'[]','pCli','Num','','','POG','Si','Colore RGB dei rami POG di natura idraulica','RGB color of the hydraulic POG branches'},...
    {'pog_Color_4'        ,'[]','pCl4','Num','','','POG','Si','Colore RGB dei rami POG di natura trasformatore o giratore','RGB color of the POG branches of type transformer and gyrator'},...
    {'pog_Color_En'      ,'[]','pClEn','Num','','','POG','Si','Colore RGB delle varibili di tipo Effort','RGB color of the Effort variables'},...
    {'pog_Color_Fn'      ,'[]','pClFn','Num','','','POG','Si','Colore RGB delle varibili di tipo Flow','RGB color of the Flow variables'},...
    {'pog_In_0'          ,'[]','In0'  ,'Str','','','POG','Si','Valore di default della variabile di ingresso','Default value of the input variable'},...
    {'pog_Kn_0'          ,'[]','Kn0'  ,'Str','','','POG','Si','Valore del parametro interno Kn','Velue of the internal parameter Kn'},...
    {'pog_Qn_0'          ,'[]','Qn0'  ,'Str','','','POG','Si','Valore iniziale della variabile energia Qn','Initial value of the energy variable Qn'},...
    {'pog_En_0'          ,'[]','En0'  ,'Str','','','POG','Si','Valore iniziale della variabile Effort En','Initial value of the effort variable En'},...
    {'pog_Fn_0'          ,'[]','Fn0'  ,'Str','','','POG','Si','Valore iniziale della variabile Flow Fn','Initial value of the flow variable Fn'},...
    {'pog_IntM'          ,'[]','pIntM','Str','','','POG','No','Il blocco Integratore precede il blocco M','The Integration block is located before the M block'},...
    {'pog_Show_Psfrag'   ,'[]','pPSF' ,'Str','','','POG','No','Indica se visualizzare o no i comandi latex di tipo psfrag sul ramo POG','Indicates if the latex commands of type psfrag must be visualized for the POG brance'},...
    {'pog_Underscore'    ,'[]','pUs'  ,'Str','','','POG','Si','Indica se lasciare gli "underscore" nel nome del ramo dello schema a blocchi POG','Indicates if the "underscore" in the brance name of the POG block scheme must be left'},...
    ... %--- Parametri POG specifici di ogni Ramo.  ----------------%
    ... % {'Lx_Snt'          ,'0' ,'PLSx','Num','','','POG','Si','Indica la larghezza del blocco verso sinistra'},...
    ... % {'Altezza'         ,'0' ,'PAlt','Num','','','POG','Si','Indica la altezza del blocco'},...
    ... %--- Parametri "doppi" di Ramo e di Sistema. Ridefinibili perr ciascun Ramo ------------------%
    {'Line_Width'   ,'[]' ,'Lw' ,'Num','','','Plot','Si','Larghezza della linea del ramo','Line width of the branch'},...
    {'Line_Type'    ,'[]' ,'Lt' ,'Str','','','Plot','Si','Tipo di tratteggio e colore delle linee del ramo','Hatch type and color of the lines of the physical branch'},...
    {'Frecce_Width' ,'[]' ,'Fw' ,'Num','','','Plot','Si','Larghezza delle frecce del ramo','Width of the arrows of the physical branch'},...
    {'Frecce_Type'  ,'[]' ,'Ft' ,'Str','','','Plot','Si','Tipo di tratteggio e colore delle frecce del ramo','Hatch type and color of the arrows of the physical branch'},...
    {'Show_X'       ,'[]' ,'ShX','Str','','','Plot','Si','Indica se visualizzare la variabile di uscita X','Indicates if the output variable X must be visualized'},...
    {'Font_X'       ,'[]' ,'FnX','Num','','','Plot','Si','Dimensione dewl font della variabile di uscita X','Font dimension of the output variable X'},...
    {'Color_X'      ,'[]' ,'ClX','Str','','','Plot','Si','Colore della variabile di uscita X','Color of the output variable X'},...
    {'Show_K'       ,'[]' ,'ShK','Str','','','Plot','Si','Indica se visualizzare il parametro interno K','Indicates if the internal parameter K must be visualized'},...
    {'Font_K'       ,'[]' ,'FnK','Num','','','Plot','Si','Dimensione del font del parametro interno K','Font dimension of the internal parameter K'},...
    {'Color_K'      ,'[]' ,'ClK','Str','','','Plot','Si','Colore del parametro interno K','Color of the internal parameter K'},...
    {'Show_Y'       ,'[]' ,'ShY','Str','','','Plot','Si','Indica se visualizzare la variabile di ingresso Y','Indicates if the input variable Y must be visualized'},...
    {'Font_Y'       ,'[]' ,'FnY','Num','','','Plot','Si','Dimensione del font della variabile di ingresso Y','Font dimension of the input variable Y'},...
    {'Color_Y'      ,'[]' ,'ClY','Str','','','Plot','Si','Colore della variabile di ingresso Y','Color of the input variable Y'},...
    {'Zoom'         ,'[]' ,'Zm' ,'Num','','','Plot','Si','Fattore di Zoom dell''elemento sul ramo','Zoom factor of the element present on the physical branch'},...
    {'Show_Labels'  ,'[]' ,'SL' ,'Str','','','Plot','Si','Indica se visualizzare o no le labels e le freccie del ramo','Indicates if the labels and the arrows of the physical branch must be visualized'},...
    {'Show_Polarita','[]' ,'Pol','Str','','','Plot','Si','Indica con piccoli "pallini" il polo positivo del ramo','Shows with small "dots" the positive pole of the physical branch'},...
    {'Extra_Dash'   ,'[]' ,'ExD','Num','','','Plot','No','Indica di quanto allungare il tratteggio del ramo ::','Indicates how much the dashed line must be lengthened'},... 
    ... %--- Parametri specifici di ciascun Ramo  ---------------------------------------------------%
    {'Out' ,'Vuoto','Out','Str','Set',{'Effort','Flow','Vuoto'},'Ramo','Si','Variabile di uscita: "E"=Effort, "F"=Flow, "Vuoto"=Indefinita','Output variable: "E"=Effort, "F"=Flow, "Vuoto"=Undefined'},...
    {'Angle'        ,'0'  ,'An' ,'Num','Real','[-180 180]'     ,'Plot','Si','Angolo che forma il ramo rispetto al nodo di partenza','Rotation angle of the physical branch'},...
    {'Lung'         ,'1'  ,'Ln' ,'Num','Real','[0.1 10]'       ,'Plot','Si','Lunghezza del ramo','Length of the physical branch'},...
    {'Shift'        ,'0'  ,'Sh' ,'Num','Real','[-5 5]'         ,'Plot','Si','Spostamento laterale del ramo','Lateral shift of the physical branch'},...
    {'Lateral'      ,'0.4','La' ,'Num','Real','[-2 2]'         ,'Plot','Si','Distanza laterale da un altro ramo','Lateral distance from another physical branch'},...
    {'Trasla'       ,'0'  ,'Tr' ,'Num','Real','[-10 10]'       ,'Plot','Si','Traslazione orizzontale dell''elemento sul ramo','Translational shift of the element along the physical branch'},...
    {'Visibile'     ,'Si' ,'Vs' ,'Str','Set' ,{'Si','No'}      ,'Plot','Si','Indica se il ramo deve essere visualizzato o no','Indicates if the physical branch must be visualized'},...
    {'E_up_down'    ,'-1' ,'Eu' ,'Num','Set' ,'[-1 1]'         ,'Plot','Si','Posizione Up/Down della trans-variabile En','Up/Down position of the across-variable En'},...
    {'K_up_down'    ,'1'  ,'Ku' ,'Num','Set' ,'[-1 1]'         ,'Plot','Si','Posizione Up/Down del parametro interno Kn','Up/Down position of the internal parameter Kn'},...
    {'Q_up_down'    ,'1'  ,'Qu' ,'Num','Set' ,'[-1 1]'         ,'Plot','Si','Posizione Up/Down della variabile energia Qn','Up/Down position of the energy variable Qn'},...
    {'F_up_down'    ,'-1' ,'Fu' ,'Num','Set' ,'[-1 1]'         ,'Plot','Si','Posizione Up/Down della per-variabile Fn','Up/Down position of the through-variable Fn'},...
    {'Pow_In'       ,'1'  ,'Pin','Num','Set' ,'[-1 1]'         ,'Ramo','Si','Segno della potenza entrante nel ramo','Sign of the power entering the physical branch'},... %% **
    {'Diretto'      ,'Si' ,'Dir','Str','Set' ,{'Si','No'}      ,'Ramo','No','Indica se il ramo e'' "Diretto" o "Inverso"','Indicates if the physical branch is "Direct" or "Inverse"'},... 
    };

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% VARIABILI DI GRAFICO E DI SISTEMA MODIFICABILI DALL'UTENTE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sistema.Parms_Sistema={...
    ... %-- Parametri POG che si applicano a tutti i Rami dello schema POG -----------------------------------------%
    {'pog_Block_S_dx'     ,'2.2'  ,'pSx' ,'Num','Real','[1 4]'     ,'POG','Si','Larghezza del blocco integratore S','Width of the integral block S'},...                                                             
    {'pog_Block_S_dy'     ,'2.2'  ,'pSy' ,'Num','Real','[1 4]'     ,'POG','Si','Altezza del blocco integratore S','Height of the integral block S'},...                                                              
    {'pog_Block_M_dx'     ,'2.7'  ,'pMx' ,'Num','Real','[1 6]'     ,'POG','Si','Larghezza del blocco proporzionale M','Width of the proportional block M'},...                                                       
    {'pog_Block_M_dy'     ,'2.7'  ,'pMy' ,'Num','Real','[1 6]'     ,'POG','Si','Altezza del blocco proporzionale M','Height  of the proportional block M'},...                                                       
    {'pog_From_S_to_M_dy' ,'1.1'  ,'pSyM','Num','Real','[0.5 3]'   ,'POG','Si','Distanza tra blocco integratore S e blocco proporzionale M','Distance between the integral block S and the proportional block M'},...
    {'pog_Space_dx'       ,'1'    ,'pSpx','Num','Real','[0.1 3]'   ,'POG','Si','Spazio libero intorno al blocco','Free space within the block'},...                                                                  
    {'pog_S_exists'       ,'Si'   ,'pSsi','Str','Set' ,{'Si','No'} ,'POG','Si','Indica se e" presente il blocco integratore','Indicates if the block is present'},...                                                
    {'pog_Effort_Su'      ,'Si'   ,'pEsu','Str','Set' ,{'Si','No'} ,'POG','Si','Indica se la variabile Efford e" posta in alto','Indicates if the effor variable En is up-located'},...                              
    {'pog_Vai_a_Destra'   ,'Si'   ,'pDst','Str','Set' ,{'Si','No'} ,'POG','Si','Indica se lo sviluppo dello schema e" verso destra','Indicates if the POG block scheme must be developed left or right'},...         
    {'pog_Line_Width'     ,'0.9'  ,'pLw' ,'Num','Real','[0.01 4]'  ,'POG','Si','Larghezza della linea del ramo POG','Line width of the POG branch'},...                                                              
    {'pog_Line_Type'      ,'k'    ,'pLt' ,'Str','Free',''          ,'POG','Si','Tipo di tratteggio e il colore delle linee del ramo POG','Hatch type and color of the lines of the POG branch'},...                  
    {'pog_Show_Y'         ,'No'   ,'pShY','Str','Set',{'Si','No'}  ,'POG','Si','Indica se visualizzare la variabile di ingresso Y','Indicates if the input variable Y must be visualized'},...                        
    {'pog_Font_Y'         ,'9'    ,'pFnY','Num','Int','[0 15]'     ,'POG','Si','Dimensione del font della variabile di ingresso Y','Font dimension of the input variable Y'},...                                      
    {'pog_Color_Y'        ,'k'    ,'pClY','Str','Set',{'b','g','r','c','m','y','k','w'} ,'POG','Si','Colore della variabile di ingresso Y','Color of the input variable Y'},...                                                            
    {'pog_Show_Q'         ,'No'   ,'pShQ','Str','Set',{'Si','No'}  ,'POG','Si','Indica se visualizzare la variabile energia Q','Indicates if the energy variable Q must be visualized'},...                           
    {'pog_Font_Q'         ,'8'    ,'pFnQ','Num','Int','[0 15]'     ,'POG','Si','Dimensione del font della variabile energia Q','Font dimension of the energy variable Q'},...                                         
    {'pog_Color_Q'        ,'k'    ,'pClQ','Str','Set',{'b','g','r','c','m','y','k','w'}  ,'POG','Si','Colore dela variabile energia Q','Color of the energy variable Q'},...                                                                
    {'pog_Show_K'         ,'Si'   ,'pShK','Str','Set',{'Si','No'}  ,'POG','Si','Indica se visualizzare il parametro interno K','Indicates if the internal parameter K must be visualized'},...                        
    {'pog_Font_K'         ,'10'   ,'pFnK','Num','Int','[0 15]'     ,'POG','Si','Dimensione del font del parametro interno K','Font dimension of the internal parameter K'},...                                        
    {'pog_Color_K'        ,'k'    ,'pClK','Str','Set',{'b','g','r','c','m','y','k','w'}  ,'POG','Si','Colore del parametro interno K','Color of the internal parameter K'},...                                                              
    {'pog_Show_X'         ,'Si'   ,'pShX','Str','Set',{'Si','No'}  ,'POG','Si','Indica se visualizzare la variabile di uscita X','Indicates if the output variable X must be visualized'},...                         
    {'pog_Font_X'         ,'10'   ,'pFnX','Num','Int','[0 15]'     ,'POG','Si','Dimensione del font della variabile di uscita X','Font dimension of the output variable X'},...                                       
    {'pog_Color_X'        ,'k'    ,'pClX','Str','Set',{'b','g','r','c','m','y','k','w'}  ,'POG','Si','Colore della variabile di uscita X','Color of the output variable X'},...                                                             
    {'pog_Show_T'         'Si'    ,'pShT','Str','Set',{'Si','No'}  ,'POG','Si','Indica se visualizzare il tratteggio','Indicates if the dashed line must be visualized'},...                                          
    {'pog_Width_T'        '0.4'   ,'pLwT','Num','Real','[0.01 2]'  ,'POG','Si','Spessore della linea di tratteggio','Width of the dashed line'},...                                                                   
    {'pog_Color_T'        '--k'   ,'pClT','Str','Free',''          ,'POG','Si','Colore e tipo della linea di tratteggio','Color and type of the dashed line'},...                                                                     
    {'pog_Visibile'       'Si'    ,'pVs' ,'Str','Set',{'Si','No'}  ,'POG','Si','Indica se il ramo POG deve essere visualizzato o no','Indicates if the POG branch must be visualized'},...                            
    {'pog_Show_Nome_Ramo','No'    ,'pSr' ,'Str','Set',{'Si','No'}  ,'POG','Si','Indica se visualizzare il nome numerico del ramo POG','Indicates if the numeric name of the POG branch must be visualized'},...       
    {'pog_Font_Nome_Ramo' ,'6'    ,'pFr' ,'Num','Int','[0 15]'     ,'POG','Si','Dimensione del font del nome numerico del ramo POG','Font dimension of the numeric name of the POG branch'},...                       
    {'pog_Color_Nome_Ramo','k'    ,'pCr' ,'Str','Set',{'b','g','r','c','m','y','k','w'}  ,'POG','Si','Colore del nome numerico del ramo POG','Color of the numeric name of the POG branch'},...                                             
    {'pog_Colored'       ,'No','pColored','Str','Set',{'Si','No'}  ,'POG','Si','Indica se il ramo POG deve essere colorato o meno','Indicates if the POG branch must be colored'},...                                 
    {'pog_Color_e'   ,'[1 0 0]'   ,'pCle','Num','Real','[0 1]'     ,'POG','Si','Colore RGB dei rami POG di natura elettro-magnetica','RGB color of the electromagnetic POG branches'},...                             
    {'pog_Color_m'   ,'[1 0 1]'   ,'pClm','Num','Real','[0 1]'     ,'POG','Si','Colore RGB dei rami POG di natura meccanico-traslazionale','RGB color of the mechanical-translational POG branches'},...              
    {'pog_Color_r'   ,'[0 0 1]'   ,'pClr','Num','Real','[0 1]'     ,'POG','Si','Colore RGB dei rami POG di natura meccanico-rotazionale','RGB color of the mechanical-rotational POG branches'},...                   
    {'pog_Color_i'   ,'[1 1 0]'   ,'pCli','Num','Real','[0 1]'     ,'POG','Si','Colore RGB dei rami POG di natura idraulica','RGB color of the hydraulic POG branches'},...                                           
    {'pog_Color_4'   ,'[0 1 0]'   ,'pCl4','Num','Real','[0 1]'     ,'POG','Si','Colore RGB dei rami POG di natura trasformatore o giratore','RGB color of the POG branches of type transformer and gyrator'},...      
    {'pog_Color_En'  ,'[0 0.5 0]','pClEn','Num','Real','[0 1]'     ,'POG','Si','Colore RGB delle varibili di tipo Effort','RGB color of the Effort variables'},...
    {'pog_Color_Fn'  ,'[0.5 0 0]','pClFn','Num','Real','[0 1]'     ,'POG','Si','Colore RGB delle varibili di tipo Flow','RGB color of the Flow variables'},...
    {'pog_In_0'      ,'0'        ,'In0'  ,'Str','Free',''           ,'POG','Si','Valore di default delle variabili di ingresso','Default values of the input variables'},...
    {'pog_Kn_0'      ,'1'        ,'Kn0'  ,'Str','Free',''           ,'POG','Si','Valore di default dei parametri internoi Kn','Default values of the internal parameters Kn'},...
    {'pog_Qn_0'      ,'0'        ,'Qn0'  ,'Str','Free',''           ,'POG','Si','Valore iniziale di default delle variabili energia Qn','Default initial values of the effort variables En'},...
    {'pog_En_0'      ,''         ,'En0'  ,'Str','Free',''           ,'POG','Si','Valore iniziale di default delle variabili Effort En','Default initial values of the flow variables Fn'},...
    {'pog_Fn_0'      ,''         ,'Fn0'  ,'Str','Free',''           ,'POG','Si','Valore iniziale di default delle variabili Flow Fn','Default initial values of the energy variables Qn'},...
    {'pog_IntM'      ,'Si'       ,'pIntM','Str','Set',{'Si','No'}  ,'POG','Si','Il blocco Integratore precede il blocco M','The Integration block is located before the M block'},...
    {'pog_Show_Psfrag','No'      ,'pPSF' ,'Str','Set',{'Si','No'}  ,'POG','Si','Indica se visualizzare o no i comandi latex di tipo psfrag sullo schema POG','Indicates if the latex commands of type psfrag must be visualized for the POG block scheme'},...
    {'pog_Underscore','No'       ,'pUs'  ,'Str','Set',{'Si','No'}  ,'POG','Si','Indica se lasciare gli "underscore" in tutti i nomi dello schema a blocchi POG','Indicates if the "underscore" of all the names of the POG block scheme must be left'},...
    ... %-- Parametri che si applicano a tutto lo schema POG  ---------------------------------------------%
    ... %-- Parametri POG che si applicano a tutti i Rami SP  ---------------------------------------------%
    {'pog_Print_POG'    ,'No'     ,'pPr' ,'Str','Set',{'Si','No'}  ,'POG','Si','Indica se stampare o meno il grafico POG','Indicates if the POG graphic must be saved in a file'},...
    {'slx_Print_SLX'    ,'No'     ,'xPr' ,'Str','Set',{'Si','No'}  ,'POG','Si','Indica se stampare o meno lo schema Simulink','Indicates if the Simulink block scheme must be saved in a file'},...
    {'sim_Print_SIM'    ,'No'     ,'sPr' ,'Str','Set',{'Si','No'}  ,'POG','Si','Indica se stampare o meno i risultati della simulazione','Indicates if the simulation results must be saved in a file'},...
    {'sim_Tfin'         ,'10'     ,'sTfin','Num','Real','[0 1000]' ,'POG','Si','Indica se stampare o meno i risultati della simulazione','Indicates if the simulation results must be saved in a file'},...
    {'sim_Nr_Ts_Points' ,'2000'   ,'sNrTs','Num','Int','[0 20000]' ,'POG','Si','Indica se stampare o meno i risultati della simulazione','Indicates if the simulation results must be saved in a file'},...
    {'pog_Graphic_Type' ,'eps'    ,'pGTy' ,'Str','Set',{'eps','epsc','jpeg','tiff','png'},'POG','Si','Tipo di immagine grafica richiesta per lo schema POG','Type of the graphical immage of the POG graphic'},...
    {'X1_Shift'         ,'1+1.5*1i','X1Sh','Num','Free',''         ,'POG','Si','Shift laterale dei blocchi SP-Foglia negli schemi POG','Lateral shift of ther "SP-Foglia" blocks within the POG schemes'},...
    {'Split_POG'        ,'0'     ,'pSplit','Str','Free',''         ,'POG','Si','Split dello schema POG in particolari punti','Split of the POG scheme in particular points'},...
    {'Split_POG_Ver_Dx','5'       ,'pSpDx','Num','Real','[2 10]'   ,'POG','Si','Distanza verticale tra due parti dello Split','Vertical distance between two splitted parts'},...
    {'Split_POG_Show_Lines','Si'  ,'pSpSL','Str','Set',{'Si','No'} ,'POG','Si','Indica se visualizzare le linee di collegamento delle parti Split','Indicates if the connection lines between the splitted parts are to be shown'},...
    ... %-- Parametri che si applicano a tutti i Rami del Grafico ---------------------------------------------%
    {'Split_Scheme'        ,'','Split' ,'Str','Free',''         ,'Grafico','Si','Indica se i rami successivi devono essere slittati','Indicates if all the next physical are to be splitted'},...
    {'Line_Width'          ,'1.2','Lw' ,'Num','Real','[0.1 3]'  ,'Grafico','Si','Spessore globale di tutte le linee del grafico','Global width of all the lines of the graphic'},...
    {'Line_Type'           ,'k'  ,'Lt' ,'Str','Free',''         ,'Grafico','Si','Tipo globale di tratteggio e colore di tutte le linee del grafico','Global hatch type and color of all the lines of the graphic'},...
    {'Frecce_Width'        ,'0.8','Fw' ,'Num','Real','[0.1 3]'  ,'Grafico','Si','Spessore globale di tutte le frecce del grafico','Global width of all the arrows of the graphic'},...
    {'Frecce_Type'         ,'k'  ,'Ft' ,'Str','Free',''         ,'Grafico','Si','Tipo globale di tratteggio e colore di tutte le frecce del grafico','Global hatch type and color of all the arrows of the graphic'},...
    {'Show_X'              ,'Si' ,'ShX','Str','Set',{'Si','No'} ,'Grafico','Si','Indica se visualizzare tutte le variabili di stato X del grafico','Indicats if all the state variables X of the graphic must be visualized'},...
    {'Font_X'              ,'10' ,'FnX','Num','Int','[0 15]'    ,'Grafico','Si','Dimensione globale del font di tutte le variabili di stato X del grafico','Global font dimension of all the state variables X of the graphic'},...
    {'Color_X'             ,'k'  ,'ClX','Str','Set',{'b','g','r','c','m','y','k','w'}  ,'Grafico','Si','Colore globale di tutte le variabili di stato X del grafico','Global color of all the state variables X of the graphic'},...
    {'Show_K'              ,'Si' ,'ShK','Str','Set',{'Si','No'} ,'Grafico','Si','Indica se visualizzare tutti i parametri interni K del grafico','Indicats if all the internal parameters K of the graphic must be visualized'},...
    {'Font_K'              ,'10' ,'FnK','Num','Int','[0 15]'    ,'Grafico','Si','Dimensione globale del font di tutti i parametri interni K del grafico','Global font dimension of all the internal parammeters K of the graphic'},...
    {'Color_K'             ,'k'  ,'ClK','Str','Set',{'b','g','r','c','m','y','k','w'}  ,'Grafico','Si','Colore globale di tutti parametri interni K del grafico','Global color of all the internal parammeters K of the graphic'},...
    {'Show_Y'              ,'No' ,'ShY','Str','Set',{'Si','No'} ,'Grafico','Si','Indica se visualizzare tutte le variabili di ingresso Y del grafico','Indicats if all the output variables Y of the graphic must be visualized'},...
    {'Font_Y'              ,'10' ,'FnY','Num','Int','[0 15]'    ,'Grafico','Si','Dimensione globale del font d di tutte le variabili di ingresso Y del grafico','Global font dimension of all the input variables Y of the graphic'},...
    {'Color_Y'             ,'k'  ,'ClY','Str','Set',{'b','g','r','c','m','y','k','w'}  ,'Grafico','Si','Colore globale di tutte le variabili di ingresso Y del grafico','Global color of all the input variables Y of the graphic'},...
    {'Zoom'                ,'1'  ,'Zm' ,'Num','Real','[0.01 10]','Grafico','Si','Fattore globale di Zoom di tutti i rami del grafico','Global zoom factor of all the brances of the graphic'},...
    {'Show_Labels'         ,'Si' ,'SL' ,'Str','Set',{'Si','No'} ,'Grafico','Si','Indica se visualizzare o no le labels e le freccie del grafico','Indicates if all the labels and arrows of the graphic must be visualized'},...
    {'Show_Psfrag'         ,'No' ,'PSF','Str','Set',{'Si','No'} ,'Grafico','No','Indica se visualizzare o no i comandi latex di tipo psfrag','Indicates if the latex commands of type psfrag must be visualized'},...
    {'Show_Polarita'       ,'Si' ,'Pol','Str','Set',{'Si','No'} ,'Grafico','Si','Indica con "pallini" il polo positivo di tutti i rami del grafico','Shows with small dots the positive pole of all the brances of the graphic'},... 
    {'Extra_Dash'          ,'0.1','ExD','Num','Real','[0.01 1]' ,'Grafico','Si','Indica di quanto allungare il tratteggio dei rami :: del grafico','Indicates how much all the dashed lines of the graphic must be lengthened'},... 
    ... %--- Parametri che si applicano al Sistema  ---------------------------------------------------%
    {'Show_Grafico'        ,'Si' ,'Gr' ,'Str','Set',{'Si','No'} ,'Grafico','Si','Indica se disegnare il grafico dello schema','Indicates if the physical graphic must be displayed'},...    
    {'Nr_Figura'           ,'0'  ,'Nf' ,'Num','Int','[0 1000]'  ,'Grafico','No','Numero della figura','Number of the figure where the physical graphic is shown'},...
    {'Print_Grafico'       ,'No' ,'Pr' ,'Str','Set',{'Si','No'} ,'Grafico','Si','Indica se stampare o meno il grafico','Indicates if the physical graphic must be saved in a file'},...
    {'Nome_del_grafico'    ,'__' ,'Ng' ,'Str','Name',''         ,'Grafico','Si','Nome da usare per il grafico','Name of file storing the the physical graphic'},...
    {'Dir_out'          ,'.\','Dir_out','Str','Free',''         ,'Grafico','No','Nome del direttorio "out"','Name of the directory "out"'},...
    {'Graphic_Type'       ,'eps','GTy' ,'Str','Set',{'eps','epsc','jpeg','tiff','png'}  ,'Grafico','Si','Tipo di immagine grafica richiesta','Type of the graphical immage of the physical graphic'},...
    {'Show_Dots'           ,'Si' ,'SD' ,'Str','Set',{'Si','No'} ,'Grafico','Si','Indica se visualizzare i "pallini" dei nodi','Indicates if the "dot" of all the nodes of the physical graphic must be visualized'},...
    {'Show_Nomi_Nodi'      ,'Si' ,'Sn' ,'Str','Set',{'Si','No'} ,'Grafico','Si','Indica se visualizzare i nomi dei nodi','Indicates if the names of all the nodes of the physical graphic must be visualized'},...
    {'Show_Nuovi_Nomi_Nodi','No' ,'SN' ,'Str','Set',{'Si','No'} ,'Grafico','No','Indica se visualizzare i nodi utilizzando i nuovi nomi','Indicates if the "new names" of the nodes of the physical graphic must be visualized'},...
    {'Font_Nodi'           ,'10' ,'FnN','Num','Int','[0 30]'    ,'Grafico','Si','Dimensione del font dei nomi dei nodi','Font dimension of all the nodes of the physical graphic'},...
    {'Color_Nodi'          ,'k'  ,'ClN','Str','Set',{'b','g','r','c','m','y','k','w'}  ,'Grafico','Si','Colore dei nomi dei nodi','Color of all the nodes of the physical graphic'},...
    {'Show_Nomi_dei_Rami'  ,'No' ,'Sr' ,'Str','Set',{'Si','No'} ,'Grafico','Si','Indica se visualizzare il numero dei rami del grafico','Indicates if the number of all the brances of the physical graphic must be visualized'},...
    {'Font_Nomi_dei_Rami'  ,'7'  ,'Fr' ,'Num','Int','[0 30]'    ,'Grafico','Si','Dimensione del font dei numeri di ramo','Font dimension of all the brances of the physical graphic'},...
    {'Color_Nomi_dei_Rami' ,'k'  ,'Cr' ,'Str','Set',{'b','g','r','c','m','y','k','w'}  ,'Grafico','Si','Colore dei numeri di ramo','Color of all the brances of the physical graphic'},...
    {'Underscore'          ,'No' ,'Us' ,'Str','Set',{'Si','No'} ,'Grafico','No','Indica se lasciare gli "underscore" in tutti i nomi del grafico','Indicates if the "underscore" of all the names of the physical graphic must be left'},...
    {'Grid'                ,'No' ,'SG' ,'Str','Set',{'Si','No'} ,'Grafico','Si','Indica se aggiungere la griglia alla figura','Indicates if a grid must be added to the physical graphic'},...
    {'Grid_Border'        ,'0.1','GrBo','Num','Real','[0 1]'    ,'Grafico','Si','Indica la larghezza del bordo da aggiungere alla griglia','Indicates the width of an additioinal border of the grid'},...
    {'Grid_Step'          ,'0.1','GrSt','Num','Real','[0 1]'    ,'Grafico','Si','Indica con quale passo mostrare la griglia','Indicates the width of the grid steps'},...
    {'Grid_Line_Type_Big' ,'-r' ,'GrLT','Str','Free',''         ,'Grafico','Si','Indica il colore e il tipo di linea delle righe maggiori','Indicates the color and the type of line of the larger lines'},...
    {'Grid_Line_Type_Small',':r','GrLt','Str','Free',''         ,'Grafico','Si','Indica il colore e il tipo di linea delle righe minori','Indicates the color and the type of line of the smaller lines'},...
    {'Grid_Line_Width'    ,'0.2','GrLw','Num','Real','[0 1]'    ,'Grafico','Si','Indica la larghezza delle linee che compongono la griglia','Indicates the width of the grid lines'},...
    {'Grid_Label_FontSize' ,'12','GrFs','Num','Int','[0 30]'    ,'Grafico','Si','Indica la grandezza del font dei numeri della griglia','Indicates the font size of the grid numbers'},...
    {'Grid_Label_FontColor', 'r','GrFc','Str','Free',''         ,'Grafico','Si','Indica il colore del font dei numeri della griglia','Indicates the font color of the grid numbers'},...
    {'Point_P0'         ,'0+1*1i','P0' ,'Num','Free',''         ,'Grafico','No','Definisce il punto di partenza P0 di uno schema POG','Defines the stating point P0 of the POG physical graphic'},...
    {'Show_Details'        ,'No' ,'Sd' ,'Str','Set',{'Si','No'} ,'Sistema','No','Visualizza i dettagli dei passaggi intermedi','Show the mathematical intermediate steps'},...
    {'Show_Lista_Rami_SP'  ,'No','SdLr','Str','Set',{'Si','No'} ,'Sistema','No','Visualizza la lista dei rami ridotti serie/parallelo','Show the list of the reduced series/parallel brances '},...
    {'Help_in_English'     ,'No','Heng','Str','Set',{'Si','No'} ,'Sistema','Si','Indica di usare Inglese nel file Help','Indicates if the english language must be used for the help file'},...
    {'Analizza_lo_Schema'  ,'Si' ,'As' ,'Str','Set',{'Si','No'} ,'Sistema','Si','Analizzare il sistema e generare le equazioni differenziali','Analyze the system and write the diferential equations'},...
    {'Genera_il_file_diary','No','diary','Str','Set',{'Si','No'},'Sistema','Si','Generare il file diary?','Do you want to generate the diary file?'},...
    {'Salva_EQN_Diff_Eqs'  ,'No' ,'EQN','Str','Set',{'Si','No'} ,'Sistema','Si','Salva le equazioni differenziali in un file txt','Save the differential equations in a txt file'},...
    {'Show_Diff_Eqs_Latex' ,'0','Latex','Str','Set',{'0','A','AB','LAB','MIN'} ,'Sistema','No','Visualizza le equazioni differenziali anche in formato Latex','Show the differential equations in latex form'},...
    {'Crea_lo_Schema_POG'  ,'No' ,'POG','Str','Set',{'Si','No'} ,'Sistema','Si','Generare lo schema POG del sistema fisico','Generate the POG block scheme of the physical system'},...
    {'Crea_lo_Schema_SLX'  ,'No' ,'SLX','Str','Set',{'Si','No'} ,'Sistema','Si','Generare lo schema Simulink del sistema fisico','Generate the Simmulink block scheme of the physical system'},...
    {'Simula_lo_Schema_SLX','No' ,'SIM','Str','Set',{'Si','No'} ,'Sistema','Si','Simula lo schema Simulink del sistema fisico','Simulate the Simmulink block scheme of the physical system'},...
    {'Show_Skew'           ,'No' ,'Skw','Str','Set',{'Si','No'} ,'Sistema','Si','Indica se mostrare la parte simmetrica ed emisimmetrica della matrice A','Indicates if the symmetric and skew-symmetric parts of matrix A must be shown'},...
    {'Show_Hs'             ,'No' ,'Hs' ,'Str','Set',{'Si','No'} ,'Sistema','Si','Indica se mostrare la matrice di trasferimento H(s) del sistema','Indicates if the ransfer matrix H(s) of the given system must be shown'},...
    {'Verifica_Old'        ,'No' ,'Old','Str','Set',{'Si','No'} ,'Sistema','No','Indica se verificare la compatibilita'' con la vecchia versione','Indicates if the compatibility with the old version must be verified'},...
    };
%     {'Help'                ,'No' ,'Help','Str','Free','','Sistema','Help sui "B"locchi, "MB"locchi, "R"ami e "S"istema'}...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% STAMPA LE STRUTTUREIN FORMATO (DA USARE QUANDO SERVE)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Sistema.Crea_Files_CSV,'Si')
    Tutti_i_Blocchi=[Sistema.Parms_Blocchi Sistema.Parms_Meta_Blocchi];
    STAMPA_CSV(Tutti_i_Blocchi,Sistema.Indice_B,'Blocchi')
    Parms_Rami=Sistema.Parms_Rami;
    Parms_Sistema=Sistema.Parms_Sistema;
    for ii=1:length(Parms_Rami)
        if strcmp(Parms_Rami{ii}{2},'[]')
            Parms_Rami{ii}(2)=Parms_Sistema{ii}(2);
            Parms_Rami{ii}(5)=Parms_Sistema{ii}(5);
        end
    end
    STAMPA_CSV(Parms_Rami,Sistema.Indice_R,'Rami')
    STAMPA_CSV(Sistema.Parms_Sistema,Sistema.Indice_R,'Sistema')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sistema=LEGGI_SCHEMA_DA_FILE(File,Schema_In)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ind=strfind(File,'.txt');
if isempty(Ind)
    File_Name = File;                                   % File_Name: nome e path del file senza estensione
    File_Name_txt = [File '.txt'];                      % File_Name_txt: nome e path del file con estensione "txt"
else
    File_Name = File(1:Ind(1)-1);
    File_Name_txt = File;
end
Ind=strfind(File_Name_txt,'\');                         % "\" � il separatore tra i campi di un indirizzo
if not(isempty(Ind))
    Dir_out=[File_Name_txt(1:Ind(end)) 'out'];          % Dir_out: direttorio di uscita  
    if not(exist(Dir_out,'dir'))
        mkdir(Dir_out);                                 % Se il direttorio Dir_out non esiste viene creato
    end
    Dir_out=[Dir_out '\'];
    File_Name=File_Name(Ind(end)+1:end);                % File_Name: nome (senza path) del file senza estensione
else
    Dir_out='.\';                                       % Dir_out coincide con il direttorio corrente
end
if exist(File_Name_txt,'file')
    A=importdata(File_Name_txt,'\n',20000); 
    Nr=size(A,1);
    B(1) = Schema_In;
    jj=2;  
    for ii=1:Nr
        A(ii)=strrep(A(ii),'''','');
        if not(strcmp(A(ii),'')||strcmp(A(ii),''''''))      % Toglie le righe vuote
            B(jj)=A(ii);
            jj=jj+1;
        end
    end
    B(jj)  ={['**, Ng, ' File_Name]};
    B(jj+1)  ={['**, Dir_out, ' Dir_out ]};
    B(jj+2)={ ''};
    B(jj+3)={ ''};
    B=B(:);
    Sistema.Title= File_Name;
    Sistema.Dir_out= Dir_out;
    Sistema.Schema_In= B;
    Sistema.Nr_Schema= 1;
else
    disp(' '); disp(['Il file "' File_Name_txt '" non esiste!'])
    Sistema.Dir_out= Dir_out;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     TO_Out=COPY_TO(FROM,TO_In)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TO_Out=TO_In;
Campi=fieldnames(FROM);
for ii=1:length(Campi)
    Campo_ii=Campi{ii};
    if not(isfield(TO_In,Campo_ii))
        TO_Out=setfield(TO_Out,Campo_ii,getfield(FROM,Campo_ii));
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     [Input_Var, Input_Color]=GET_COLOR_OF_INPUT_VARIABLE(Ramo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Input_Var=char(Ramo.E_name);            % Effort variable En
Input_Color=Ramo.POG.pog_Color_En;      % Input_Color = Dark Green (Effort)
if strcmp(Ramo.Out,'Effort')            % If the output variable is an Effort
    Input_Var=char(Ramo.F_name);        % ... the input variable is a Flow 
    Input_Color=Ramo.POG.pog_Color_Fn;  % Input_Color = Dark Red (Flow)
end
if strcmp(Ramo.POG.pog_Colored,'No')
    Input_Color=Ramo.POG.pog_Color_Y;   % Default Input Color
end
% Input_Var=strrep(Input_Var,'_','');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     [Output_Var, Input_Var, Output_Color]=GET_COLOR_OF_OUTPUT_VARIABLE(Ramo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Output_Var=char(Ramo.E_name);           % Effort variable En
Input_Var =char(Ramo.F_name);           % Flow variable Fn
Output_Color=Ramo.POG.pog_Color_En;     % Output_Var = Dark Green (Effort)
if strcmp(Ramo.Out,'Flow')              % If the output variable is a Flow
    Output_Var=char(Ramo.F_name);       % ... the output variable is a Flow
    Input_Var =char(Ramo.E_name);       % ... the input variable is a Effort
    Output_Color=Ramo.POG.pog_Color_Fn; % Output_Var = Dark Red (Flow)
end
if strcmp(Ramo.POG.pog_Colored,'No')
    Output_Color=Ramo.POG.pog_Color_X;  % Default Output Color
end
% Output_Var=strrep(Output_Var,'_','');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     String=GET_KN(Ramo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(Ramo.TR_o_GY)
    if strcmp(Ramo.POG.MxM,'Si')        % Parametro dell'elemento dinamico
        if strcmp(Ramo.Diretto,'No')
            String=Ramo.K_name;
        else
            String=1/Ramo.K_name;
        end
    else
        if strcmp(Ramo.Diretto,'Si')
            if strcmp(Ramo.Out,'Effort')
                String=Ramo.K_name;
            else
                String=1/Ramo.K_name;
            end
        else
            if strcmp(Ramo.Out,'Effort')
                String=1/Ramo.K_name;
            else
                String=Ramo.K_name;
            end
        end
    end
else
    String=Ramo.K_name;
end
% String=char(String);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     PLOT_TEXT(Points,String,Command,FontSize,Color,POG)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
String_Text=String;
if strcmp(POG.pog_Underscore,'No')
    String_Text=strrep(String,'_','');
end
Horizontal='center';
if strfind(Command,'snt')
    Horizontal='left';
elseif strfind(Command,'dst')
    Horizontal='right';
end
%%%%%%%
Vertical='middle';
if strfind(Command,'su')
    Vertical='top';
elseif strfind(Command,'giu')
    Vertical='bottom';
end
%%%%%%%
text(real(Points),imag(Points),String_Text,'HorizontalAlignment',Horizontal,'VerticalAlignment',Vertical,'FontSize',FontSize,'Color',Color)
if strcmp(POG.pog_Show_Psfrag,'Si')
    if Vertical(1)=='m'; Vertical(1)='c'; end
    MOSTRA_STRINGA_PSFRAG(String,String_Text,Horizontal(1),Vertical(1))
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function    MOSTRA_STRINGA_PSFRAG(String,String_Text,orz,ver)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
String_Psfrag=String;
Str3='';
Ind=strfind(String_Psfrag,'=');
if not(isempty(Ind))
    String_Psfrag=[String_Psfrag(1:Ind(1)-1) '\!=\!' String_Psfrag(Ind(1)+1:end)];
    Str3='[0.7]';
end
Ind=strfind(String_Psfrag,'_');
if not(isempty(Ind))
    Str1=String_Psfrag(1:Ind(1));
    Str2=String_Psfrag(Ind(1)+1:end);
    Str2=strrep(Str2,'_','');
    if length(Str2)==1
        String_Psfrag=[Str1 Str2];
    else
        String_Psfrag=[Str1 '{' Str2 '}'];
    end
end
Ind=strfind(String_Psfrag,'1/');
if not(isempty(Ind))
    Str1=String_Psfrag(1:Ind(1)-1);
    Str2=String_Psfrag(Ind(1)+2:end);
    String_Psfrag=[Str1 '\frac{1}{' Str2 '}'];
end
disp([' \psfrag{' String_Text '}[' orz ver '][' orz ver ']' Str3 '{$' String_Psfrag '$}' ])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return
        

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Lista_Rami = POG_FROM_FOGLIA_TO_SP(Lista_Rami,ii)  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OGNI RAMO 'SP' EREDITA LA STRUTURA 'POG' DEL SUO PRIMO ELEMENTO FOGLIA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ramo_ii=Lista_Rami(ii);
for ii=1:length(Ramo_ii.SP_Rami)
    jj=abs(Ramo_ii.SP_Rami(ii));
    if not(strcmp(Lista_Rami(jj).SP,'Foglia'))
        Lista_Rami=POG_FROM_FOGLIA_TO_SP(Lista_Rami,jj);
    end
end
Ramo_ii.POG=Lista_Rami(abs(Ramo_ii.SP_Rami(1))).POG;
Lista_Rami(ii)=Ramo_ii;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [X0,Y0,X1,Y1] = CALCOLA_ESTREMI(Posizione_Nodi)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Posizione_Nodi=Posizione_Nodi(Posizione_Nodi~=Inf);
if isempty(Posizione_Nodi)
    X0=0; Y0=0; X1=0; Y1=0;
else
    X0=min(real(Posizione_Nodi));
    Y0=min(imag(Posizione_Nodi));
    X1=max(real(Posizione_Nodi));
    Y1=max(imag(Posizione_Nodi));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sistema=DISEGNA_LO_SCHEMA(Sistema)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Lista_Rami=Sistema.Lista_Rami;
Lista_Nodi=Sistema.Lista_Nodi;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% GRAFICAZIONE DELLO SCHEMA  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if Sistema.Grafico.Nr_Figura==0
    figure(Sistema.Nr_Schema)
else
    figure(Sistema.Grafico.Nr_Figura)
end
clf; hold on
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% GRAFICAZIONE DELLA GRIGLIA  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Sistema.Grafico.Grid,'Si')
    Grid_Border=Sistema.Grafico.Grid_Border;                    % Bordo
    Grid_Step=Sistema.Grafico.Grid_Step;                        % Passo
    Grid_Line_Type_Big=Sistema.Grafico.Grid_Line_Type_Big;      % Tipo delle linee  maggiori della griglia
    Grid_Line_Type_Small=Sistema.Grafico.Grid_Line_Type_Small;	% Tipo delle linee  minori della griglia
    Grid_Line_Width=Sistema.Grafico.Grid_Line_Width;            % Linea
    Grid_Label_FontSize=Sistema.Grafico.Grid_Label_FontSize;
    Grid_Label_FontColor=Sistema.Grafico.Grid_Label_FontColor;
    %%%%%%%%%%%%%%%%%%
    Posizione_Nodi=[Lista_Nodi.Posizione];
    [X0,Y0,X1,Y1]=CALCOLA_ESTREMI(Posizione_Nodi);
    X0=X0-2*Grid_Border;
    Y0=Y0-Grid_Border;
    X1=X1+3*Grid_Border;
    Y1=Y1+Grid_Border;
    for Xii=X0:Grid_Step:X1                    % Linee verticali sottili
        plot([1 1]*Xii, [Y0 Y1],Grid_Line_Type_Small,'LineWidth',Grid_Line_Width)
    end
    for Xii=ceil(X0):floor(X1)          % Linee verticali spesse +  Tags
        plot([1 1]*Xii, [Y0 Y1],Grid_Line_Type_Big,'LineWidth',Grid_Line_Width)
        text(Xii,Y0-0.02,num2str(Xii),'VerticalAlignment','top','HorizontalAlignment','center','Color',Grid_Label_FontColor,'FontSize',Grid_Label_FontSize)
    end
    for Yii=Y0:Grid_Step:Y1                    % Linee orizzontali sottili
        plot([X0 X1], [1 1]*Yii,Grid_Line_Type_Small,'LineWidth',Grid_Line_Width)
    end
    for Yii=ceil(Y0):floor(Y1)          % Linee orizzontali spesse +  Tags
        plot([X0 X1], [1 1]*Yii,Grid_Line_Type_Big,'LineWidth',Grid_Line_Width)
        text(X0-0.02,Yii,num2str(Yii),'VerticalAlignment','middle','HorizontalAlignment','right','Color',Grid_Label_FontColor,'FontSize',Grid_Label_FontSize)
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% GRAFICAZIONE DEI SINGOLI RAMI  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Opzioni.Grafico=Sistema.Grafico;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Lista_Nodi(1).Pos_A=[];                         % Aggiunge il campo "Pos_A" a Lista_Nodi
for ii=1:Sistema.Nr_dei_Nodi
    Lista_Nodi(ii).Posizione=APPROX_N_DIGITS(Lista_Nodi(ii).Posizione,3);
    Lista_Nodi(ii).OK='No';
end
Str=['/' Sistema.Grafico.Split_Scheme '/'];     % Inserisce separatori
Ind_Nodi=strfind(Str,'/');
for jj=1:length(Ind_Nodi)-1
    Nodo_jj=Str(Ind_Nodi(jj)+1:Ind_Nodi(jj+1)-1);                               % Nodo_Split jj-esimo (Nome_Vero)
    [Split_scheme, Nodo_Nome_Nuovo]=ismember(Nodo_jj,[Lista_Nodi.Nome_Vero]);   % Il Nodo_Split � uno di quelli presenti nel sistema?
    if Split_scheme                                                             % Nodo_Nome_Nuovo � il nuovo nome del Nodo
        Pos_X_Split=real(Lista_Nodi(Nodo_Nome_Nuovo).Posizione);    % Posizione X di Split
        Sposta=-Pos_X_Split-1.6*1i;                                 % Vettore di spostamento Split
        Pos_X_Nodi=real([Lista_Nodi.Posizione]);                    % Posizione X dei Nodi  
        Nodi=find(Pos_X_Nodi==Pos_X_Split);                         % Individua tutti i Nodi Nuovi che hanno la stessa posizione Pos_X_Split
        Nodi=Nodi(strcmp({Lista_Nodi([Nodi]).OK},'No'));
        if length(Nodi)>=2
            From_Pos=real([Lista_Nodi([Lista_Rami.From]).Posizione]);
            To_Pos=real([Lista_Nodi([Lista_Rami.To]).Posizione]);
            OK_Split=prod(logical((From_Pos<=Pos_X_Split).*(To_Pos<=Pos_X_Split)+ ...
                (From_Pos>=Pos_X_Split).*(To_Pos>=Pos_X_Split)));
            if OK_Split
                for ii=1:Sistema.Nr_dei_Nodi
                    if strcmp(Lista_Nodi(ii).OK,'No')
                        Pos_Nodo=Lista_Nodi(ii).Posizione;
                        if real(Pos_Nodo)<Pos_X_Split
                            Lista_Nodi(ii).OK='Si';
                        elseif real(Pos_Nodo)==Pos_X_Split
                            Lista_Nodi(ii).Pos_A=Pos_Nodo+Sposta;
                            Lista_Nodi(ii).OK='Si';
                        elseif real(Pos_Nodo)>Pos_X_Split
                            Lista_Nodi(ii).Posizione=Pos_Nodo+Sposta;
                        end
                    end
                end
                Pos_Y_Nodi=imag([Lista_Nodi(Nodi).Posizione]);
                plot([1 1]*Pos_X_Split, [max(Pos_Y_Nodi)+0.1 min(Pos_Y_Nodi)-0.1 ],'--')
                h=text(Pos_X_Split+0.1, mean([max(Pos_Y_Nodi) min(Pos_Y_Nodi)]),'...','FontSize',18,'HorizontalAlignment','left');
                plot([0 0], [max(Pos_Y_Nodi)+0.1 min(Pos_Y_Nodi)-0.1 ]+imag(Sposta),'--')
                text(-0.1, mean([max(Pos_Y_Nodi) min(Pos_Y_Nodi)]+imag(Sposta)),'...','FontSize',18,'HorizontalAlignment','right')
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii=1:Sistema.Nr_dei_Rami
    Ramo_ii=Lista_Rami(ii);
    if strcmp(Ramo_ii.Plot.Visibile,'Si')
        Opzioni.Ramo_ii=Ramo_ii;
        if not(isempty(Ramo_ii.Gemello))
            Opzioni.Ramo_jj=Lista_Rami(ii+Ramo_ii.Gemello);
        end
        P1=Lista_Nodi(Ramo_ii.From_Plot).Posizione;
        P1A=Lista_Nodi(Ramo_ii.From_Plot).Pos_A;
        P2=Lista_Nodi(Ramo_ii.To_Plot).Posizione;
        P2A=Lista_Nodi(Ramo_ii.To_Plot).Pos_A;
        P1_Split=not(isempty(P1A)); P1_Non_Split=isempty(P1A);
        P2_Split=not(isempty(P2A)); P2_Non_Split=isempty(P2A);
        if (P1_Non_Split)&&(P2_Non_Split)
                DISEGNA_IL_RAMO_II(Opzioni,Ramo_ii,P1,P2,ii)
        elseif (P1_Non_Split)&&(P2_Split)
            if real(P1)<real(P2)
                DISEGNA_IL_RAMO_II(Opzioni,Ramo_ii,P1,P2,ii)
            elseif real(P1)>real(P2A)
                DISEGNA_IL_RAMO_II(Opzioni,Ramo_ii,P1,P2A,ii)
            end
        elseif (P1_Split)&&(P2_Non_Split)
            if real(P1A)<real(P2)
                DISEGNA_IL_RAMO_II(Opzioni,Ramo_ii,P1A,P2,ii)
            elseif real(P2)>real(P1)
                DISEGNA_IL_RAMO_II(Opzioni,Ramo_ii,P1,P2,ii)
            end
        elseif (P1_Split)&&(P2_Split)
            if Ramo_ii.Plot.Shift<=0
                DISEGNA_IL_RAMO_II(Opzioni,Ramo_ii,P1,P2,ii)
            else
                DISEGNA_IL_RAMO_II(Opzioni,Ramo_ii,P1A,P2A,ii)
            end
        end
    end
end
axis equal; axis off; zoom on
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% GRAFICAZIONE DEI PUNTI NODALI DELLO SCHEMA  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dx=0.01;      % Raggio dei punti nodali
if strcmp(Sistema.Grafico.Show_Dots,'Si')
    for ii=(1:Sistema.Nr_dei_Nodi)
        punto=Lista_Nodi(ii).Posizione+dx*exp(1i*2*pi*(0:0.01:1));
        patch(real(punto),imag(punto),'k')
        if not(isempty(Lista_Nodi(ii).Pos_A))
            punto=Lista_Nodi(ii).Pos_A+dx*exp(1i*2*pi*(0:0.01:1));
            patch(real(punto),imag(punto),'k')
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% GRAFICAZIONE DEI NOMI DEI NODI  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Sistema.Grafico.Show_Nomi_Nodi,'Si')
    for ii=(1:Sistema.Nr_dei_Nodi)
        P1=4*dx*exp(1i*pi/4);
        punto=Lista_Nodi(ii).Posizione;
        e_jAngle=exp(-1i*pi/4);
        Opzioni.P5=punto; Opzioni.Angle=e_jAngle;
        if strcmp(Sistema.Grafico.Show_Nuovi_Nomi_Nodi,'Si')
            ROTO_TRASLA_TESTO(P1,num2str(Lista_Nodi(ii).Nome),Opzioni,'Nodo')
        else
            ROTO_TRASLA_TESTO(P1,Lista_Nodi(ii).Nome_Vero{1},Opzioni,'Nodo')
        end
        if not(isempty(Lista_Nodi(ii).Pos_A))
            punto=Lista_Nodi(ii).Pos_A;
            e_jAngle=exp(-1i*pi/4);
            Opzioni.P5=punto; Opzioni.Angle=e_jAngle;
            if strcmp(Sistema.Grafico.Show_Nuovi_Nomi_Nodi,'Si')
                ROTO_TRASLA_TESTO(P1,num2str(Lista_Nodi(ii).Nome),Opzioni,'Nodo')
            else
                ROTO_TRASLA_TESTO(P1,Lista_Nodi(ii).Nome_Vero{1},Opzioni,'Nodo')
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% STAMPA IL GRAFICO DELLO SCHEMA FISICO NEL FORMATO RICHIESTO  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Opzioni.Grafico.Print_Grafico,'Si')
    PRINT_FIGURA([Sistema.Grafico.Dir_out Sistema.Grafico.Nome_del_grafico],Opzioni.Grafico.Graphic_Type,'_SCH')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     PRINT_FIGURA(Nome_del_grafico,Graphic_Type,Add_Str)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch Graphic_Type
    case {'eps','epsc','jpeg','tiff','png'}
    otherwise
        Graphic_Type='epsc';
        beep;
        disp(['L''immagine viene salvata in formato ' Graphic_Type ])
end
if strcmp(Add_Str,'_SLX')
    eval(['print -s -r0 -d' Graphic_Type ' ' Nome_del_grafico Add_Str '.' Graphic_Type])
else
    eval(['print -r0 -d' Graphic_Type ' ' Nome_del_grafico Add_Str ])
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function       y = APPROX_N_DIGITS(x,n)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fornisce in uscita y il valore x letto in ingresso approssimato a n decimali
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
y=round((10^n)*x)/(10^n);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function       DISEGNA_IL_RAMO_II(Opzioni,Ramo_ii,P1,P2,ii)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Lung_P1_P2=abs(P2-P1);
e_jAngle=(P2-P1)/Lung_P1_P2;
P3=P1+1i*e_jAngle*Ramo_ii.Plot.Shift;   % Traslazione laterale del ramo i-esimo
P4=P2+1i*e_jAngle*Ramo_ii.Plot.Shift;   %       "           "           "
Lung=0.5;                               % Lunghezza standard degli elementi dello schema
Lung=Lung*Ramo_ii.Plot.Zoom;            % Lunghezza dell'elemento i-esimo presente sul ramo
if Lung>Lung_P1_P2
    Lung=Lung_P1_P2;                    % La lunghezza dell'elemento non pu� eccedere quella del ramo
end
Lung_residua=Lung_P1_P2-Lung;           % Lunghezza residua sulla quale pu� agire la traslazione
Trasla=Ramo_ii.Plot.Trasla;             % Traslazione longitudinale dell'elemento i-esimo presente sul ramo
if abs(Trasla)>Lung_residua/2
    Trasla=Trasla*Lung_residua/(2*abs(Trasla));  % La traslazione non pu� superare la lunghezza residua
end
P5=P3+e_jAngle*(Lung_residua/2+Trasla);
P6=P4-e_jAngle*(Lung_residua/2-Trasla);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   GRAFICAZIONE DELLE LINEE DI COLLEGAMENTO LATERALI P1-P3-P5 E P2-P3-P4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Opzioni.P5=0; Opzioni.Angle=1;
switch Ramo_ii.Nome_Ramo
    case {'|^','|>','^>','||'}  %%%% SOLO TENSIONE, SOLO CORRENTE, TENSIONE-CORRENTE, RAMO APERTO
        %%% Non si disegna nulla
    case {'::',':^'}            %%%% TRATTEGGIO, TRATTEGGIO CON FRECCE
        Extra_Dash=Opzioni.Ramo_ii.Plot.Extra_Dash;
        ROTO_TRASLA({[P3+Extra_Dash*(P3-P4) P5]},Opzioni,'Linea')  %     (From)            (To)
        ROTO_TRASLA({[P4-Extra_Dash*(P3-P4) P6]},Opzioni,'Linea')  %       P1               P2
    otherwise                                                      %       *  <-----------  *
        ROTO_TRASLA({[P1 P3]},Opzioni,'Linea')                     %       |                |
        ROTO_TRASLA({[P2 P4]},Opzioni,'Linea')                     %       |                |
        ROTO_TRASLA({[P3 P5]},Opzioni,'Linea')                     %       *----*      *----*
        ROTO_TRASLA({[P4 P6]},Opzioni,'Linea')                     %       P3   P5     P6   P4
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% GRAFICAZIONE DEI PUNTI DI POLARITA' DEI RAMI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dx=0.005;           % Raggio dei punti di polarita'
if strcmp(Opzioni.Ramo_ii.Plot.Show_Polarita,'Si')&&(strcmp(Ramo_ii.Out,'Vuoto'))
    punto=P5+dx*exp(1i*2*pi*(0:0.01:1));
    patch(real(punto),imag(punto),'k')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GRAFICAZIONE DEL NUMERO DI RAMO SE GRAFICO.SHOW_NOMI_DEI_RAMI='SI'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Opzioni.P5=(P4*0.3+P6*0.7); Opzioni.Angle=e_jAngle;
ROTO_TRASLA_TESTO(-1i*0.02,num2str(ii),Opzioni,'Ramo')
%
Opzioni.Lung=Lung; Opzioni.P5=P5; Opzioni.Angle=e_jAngle; Opzioni.Ramo_ii=Ramo_ii;
switch Ramo_ii.Nome_Ramo
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% BLOCCHI DI TIPO FILO
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case '|>'                       %%%% SOLO CORRENTE
        Ratio_Larg=0;               % Ratio_Larg = Larghezza/Lung
        Ratio_Lung=0;               % Ratio_Lung = Lunghezza/Lung
        LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Freccia_Flow')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case '|^'                       %%%% SOLO TENSIONE
        Ratio_Larg=0;               % Ratio_Larg = Larghezza/Lung
        Ratio_Lung=0;               % Ratio_Lung = Lunghezza/Lung
        LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Freccia_Effort')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case '::'                       %%%% TRATTEGGIO
        ROTO_TRASLA({Lung*[0 1]},Opzioni,'Linea')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case '^>'                       %%%% TENSIONE-CORRENTE
        Ratio_Larg=0;               % Ratio_Larg = Larghezza/Lung
        Ratio_Lung=0;               % Ratio_Lung = Lunghezza/Lung
        LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Freccia_Effort')
        LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Freccia_Flow')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case ':^'                       %%%% TRATTEGGIO CON FRECCE
        Ratio_Larg=0;               % Ratio_Larg = Larghezza/Lung
        Ratio_Lung=0;               % Ratio_Lung = Lunghezza/Lung
        ROTO_TRASLA({Lung*[0 1]},Opzioni,'Linea')
        LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Tratteggio_con_frecce')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case '||'                       %%%% RAMO APERTO
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case '--'                       %%%% CORTO CIRCUITO
        ROTO_TRASLA({Lung*[0 1]},Opzioni,'Linea')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% BLOCCHI ELETTRICI
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'eU'                       %%%% GENERATORE ELETTRICO
        switch Opzioni.Ramo_ii.Out
            case 'Vuoto'
                Ratio_Lung=0.4;             % Ratio_Lung = Spazio_occupato_dai_due_cerchi/Lung
                Ratio_Larg=Ratio_Lung;      % Ratio_Larg = Ratio_Lung
                Ratio_Dist=Ratio_Lung/3;    % Ratio_Dist = Distanza_tra_i_centri_dei_due_cerchi/Lung
                punti1=Lung*[0 (1-Ratio_Lung)/2];
                punti2=Lung*(0.5-Ratio_Dist/2+(Ratio_Lung-Ratio_Dist)*exp(1i*(0:0.01:1)*2*pi)/2);
                punti3=Lung*(0.5+Ratio_Dist/2+(Ratio_Lung-Ratio_Dist)*exp(1i*(0:0.01:1)*2*pi)/2);
                punti4=Lung*[(1+Ratio_Lung)/2 1];
                ROTO_TRASLA({punti1; punti2; punti4},Opzioni,'Linea')
                Opzioni.Ramo_ii.Plot.Line_Type=[':' Opzioni.Ramo_ii.Plot.Line_Type];
                ROTO_TRASLA({punti3},Opzioni,'Linea')
                K_name=Opzioni.Ramo_ii.K_name;  Opzioni.Ramo_ii.K_name=' ';
                LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Blocco_Resistivo')
                Opzioni.Ramo_ii.K_name=K_name;
            case 'Effort'
                Ratio_Larg=0.35;            % Ratio_Larg = Diametro/Lung
                Ratio_Lung=Ratio_Larg;      % Ratio_Lung = Ratio_Larg
                punti1=Lung*[0 (1-Ratio_Larg)/2];
                punti2=Lung*(0.5+Ratio_Larg*exp(1i*(0:0.01:1)*2*pi)/2);
                punti3=Lung*[(1+Ratio_Larg)/2 1];
                ROTO_TRASLA({punti1; punti2; punti3},Opzioni,'Linea')
                LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Ingresso_Effort')
            case 'Flow'
                Ratio_Lung=0.4;             % Ratio_Lung = Spazio_occupato_dai_due_cerchi/Lung
                Ratio_Larg=Ratio_Lung;    % Ratio_Larg = Ratio_Lung
                Ratio_Dist=Ratio_Lung/3;    % Ratio_Dist = Distanza_tra_i_centri_dei_due_cerchi/Lung
                punti1=Lung*[0 (1-Ratio_Lung)/2];
                punti2=Lung*(0.5-Ratio_Dist/2+(Ratio_Lung-Ratio_Dist)*exp(1i*(0:0.01:1)*2*pi)/2);
                punti3=Lung*(0.5+Ratio_Dist/2+(Ratio_Lung-Ratio_Dist)*exp(1i*(0:0.01:1)*2*pi)/2);
                punti4=Lung*[(1+Ratio_Lung)/2 1];
                ROTO_TRASLA({punti1; punti2; punti3; punti4},Opzioni,'Linea')
                LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Ingresso_Flow')
        end
        DISEGNA_SCATOLA(P3,P4,P5,P6,Opzioni)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'eC'                       %%%% CAPACITA' C
        Ratio_Larg=0.6;             % Ratio_Larg = Larghezza_dei_dischi/Lung
        Ratio_Lung=0.2;             % Ratio_Lung = Distanza_tra_i_dischi/Lung
        punti1=Lung*([0 (1-Ratio_Lung)/2]);
        punti2=Lung*([1 1]*(1-Ratio_Lung)/2+1i*Ratio_Larg*[1 -1]/2);
        punti3=Lung*([1 1]*(1+Ratio_Lung)/2+1i*Ratio_Larg*[1 -1]/2);
        punti4=Lung*([(1+Ratio_Lung)/2 1]);
        ROTO_TRASLA({punti1; punti2; punti3; punti4},Opzioni,'Linea')
        LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Blocco_Effort')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'eL'                       %%%% INDUTTANZA L
        Nr_spire=4;                 % Nr_spire = Numero_di_spire_dell'induttanza
        Ratio_Larg=0.3;             % Ratio_Larg = Larghezza_delle_spire/Lung
        Ratio_Lung=0.8;             % Ratio_Lung = Spazio_occupato_dalla_induttanza/Lung
        Nr_semigiri=2*Nr_spire+3;
        px=Ratio_Lung*(0:0.001:(2*Nr_spire+1)/Nr_semigiri);
        th=-pi-2*pi*px/(2*Ratio_Lung/(Nr_semigiri));
        punti1=Lung*[0 (1-Ratio_Lung)/2];
        punti2=Lung*((1-Ratio_Lung)/2+(px+Ratio_Lung*(1+cos(th))/Nr_semigiri+1i*Ratio_Larg*sin(th)/2));
        punti3=Lung*[(1+Ratio_Lung)/2 1];
        ROTO_TRASLA({punti1; punti2; punti3},Opzioni,'Linea')
        LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Blocco_Flow')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case {'eR','eG'}                %%%% RESISTENZA R e CONDUTTANZA G
        Nr_denti=10;                % Nr_denti = Numero_di_denti_della_resistenza
        Ratio_Larg=0.3;             % Ratio_Larg = Larghezza_dei_denti/Lung
        Ratio_Lung=0.8;             % Ratio_Lung = Spazio_occupato_dalla_resistenza/Lung
        px=Ratio_Lung*(0:1/(2*Nr_denti):1);
        punti1=Lung*[0 (1-Ratio_Lung)/2];
        punti2=Lung*((1-Ratio_Lung)/2+(px+1i*Ratio_Larg*sin(2*pi*px/(2*Ratio_Lung/(Nr_denti)))/2));
        punti3=Lung*[(1+Ratio_Lung)/2 1];
        ROTO_TRASLA({punti1; punti2; punti3},Opzioni,'Linea')
        LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Blocco_Resistivo')
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% BLOCCHI MECCANICI TRASLAZIONALI
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'mU'                       % MECCANICO TRASLAZIONALE
        switch Opzioni.Ramo_ii.Out
            case 'Vuoto'
                Ratio_Lung=0.5;             % Ratio_Lung = Spazio_occupato_dai_due_rombi/Lung
                Ratio_Larg=Ratio_Lung;      % Ratio_Larg = Ratio_Lung
                Ratio_Dist=Ratio_Lung/3;    % Ratio_Dist = Distanza_tra_i_centri_dei_due_rombi/Lung
                punti1=Lung*[0 (1-Ratio_Lung)/2];
                punti2=Lung*(0.5-Ratio_Dist/2+(Ratio_Lung-Ratio_Dist)*exp(1i*(0:0.25:1)*2*pi)/2);
                punti3=Lung*(0.5+Ratio_Dist/2+(Ratio_Lung-Ratio_Dist)*exp(1i*(0:0.25:1)*2*pi)/2);
                punti4=Lung*[(1+Ratio_Lung)/2 1];
                ROTO_TRASLA({punti1; punti2; punti4},Opzioni,'Linea')
                Opzioni.Ramo_ii.Plot.Line_Type=[':' Opzioni.Ramo_ii.Plot.Line_Type];
                ROTO_TRASLA({punti3},Opzioni,'Linea')
                K_name=Opzioni.Ramo_ii.K_name;  Opzioni.Ramo_ii.K_name=' ';
                LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Blocco_Resistivo')
                Opzioni.Ramo_ii.K_name=K_name;
            case 'Effort'
                Ratio_Larg=0.35;            % Ratio_Lung = Diametro/Lung
                Ratio_Lung=Ratio_Larg;      % Ratio_Lung = Ratio_Larg
                punti1=Lung*[0 (1-Ratio_Larg)/2];
                punti2=Lung*(0.5+Ratio_Larg*exp(1i*(0:0.25:1)*2*pi)/2);
                punti3=Lung*[(1+Ratio_Larg)/2 1];
                ROTO_TRASLA({punti1; punti2; punti3},Opzioni,'Linea')
                LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Ingresso_Effort')
            case 'Flow'
                Ratio_Lung=0.5;             % Ratio_Lung = Spazio_occupato_dai_due_rombi/Lung
                Ratio_Larg=Ratio_Lung;      % Ratio_Larg = Ratio_Lung
                Ratio_Dist=Ratio_Lung/3;    % Ratio_Dist = Distanza_tra_i_centri_dei_due_rombi/Lung
                punti1=Lung*[0 (1-Ratio_Lung)/2];
                punti2=Lung*(0.5-Ratio_Dist/2+(Ratio_Lung-Ratio_Dist)*exp(1i*(0:0.25:1)*2*pi)/2);
                punti3=Lung*(0.5+Ratio_Dist/2+(Ratio_Lung-Ratio_Dist)*exp(1i*(0:0.25:1)*2*pi)/2);
                punti4=Lung*[(1+Ratio_Lung)/2 1];
                ROTO_TRASLA({punti1; punti2; punti3; punti4},Opzioni,'Linea')
                LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Ingresso_Flow')
        end
        DISEGNA_SCATOLA(P3,P4,P5,P6,Opzioni)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'mM'                       % Massa M
        Ratio_Larg=0.5;             % Ratio_Larg = Larghezza_della_massa/Lung
        Ratio_Lung=0.5;             % Ratio_Lung = Lunghezza_della_massa/Lung
        punti1=Lung*([0 (1-Ratio_Lung)/2]);
        a=Ratio_Lung; c=Ratio_Larg; punti0=([-a -a a a -a]+1i*[-c c c -c -c])/2;
        punti2=Lung*(0.5+punti0);
        punti3=Lung*(0.5+0.5*punti0);
        punti4=Lung*([(1+Ratio_Lung)/2 1]);
        punti5=Lung*([(1-Ratio_Lung)/2 0.5+0.25*Ratio_Larg]);
        ROTO_TRASLA({punti1; punti2; punti3; punti4 ; punti5 },Opzioni,'Linea')
        patch(real(P5+e_jAngle*punti3),imag(P5+e_jAngle*punti3),[1 1 1]*0.7)
        LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Blocco_Effort')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case {'mE','mK'}                % Elasticit� E e Rigidit� K traslazionali
        Nr_denti=8;                 % Nr_denti = Numero_di_denti_della_resistenza
        Ratio_Larg=0.3;             % Ratio_Larg = Larghezza_dei_denti/Lung
        Ratio_Lung=0.9;             % Ratio_Lung = Spazio_occupato_dalla_resistenza/Lung
        px=Ratio_Lung*(0:1/(2*Nr_denti):1);
        punti1=Lung*[0 (1-Ratio_Lung)/2];
        punti2=Lung*((1-Ratio_Lung)/2+(px+1i*Ratio_Larg*sin(2*pi*px/(2*Ratio_Lung/(Nr_denti)))/2));
        punti3=Lung*[(1+Ratio_Lung)/2 1];
        ROTO_TRASLA({punti1; punti2; punti3},Opzioni,'Linea')
        LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Blocco_Flow')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case {'mD','mB'}                % Coefficiente d'attrito traslazionale B e il suo reciproco D
        Ratio_Larg=0.3;             % Ratio_Larg = Larghezza_dell'elemento/Lung
        Ratio_Lung=0.4;             % Ratio_Lung = Lunghezza_dell'elemento/Lung
        punti1=Lung*[0 0.5];
        a=Ratio_Lung; c=Ratio_Larg; punti0=([-a a a -a]+1i*[c c -c -c])/2;
        punti2=Lung*(0.5+punti0);
        punti0=1i*[c -c]/2;
        punti3=Lung*(0.5+0.9*punti0);
        punti4=Lung*([(1+Ratio_Lung)/2 1]);
        ROTO_TRASLA({punti1; punti2; punti3; punti4 },Opzioni,'Linea')
        LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Blocco_Resistivo')
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% BLOCCHI MECCANICI ROTAZIONALI
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'rU'                       % Generatore MECCANICO ROTAZIONALE
        switch Opzioni.Ramo_ii.Out
            case 'Vuoto'
                Ratio_Lung=0.4;             % Ratio_Lung = Spazio_occupato_dai_due_cerchi/Lung
                Ratio_Larg=Ratio_Lung;      % Ratio_Larg = Ratio_Lung
                Ratio_Dist=Ratio_Lung/3;    % Ratio_Dist = Distanza_tra_i_centri_dei_due_cerchi/Lung
                punti1=Lung*[0 (1-Ratio_Lung)/2];
                punti2=Lung*(0.5-Ratio_Dist/2+(Ratio_Lung-Ratio_Dist)*exp(1i*(0:0.01:1)*2*pi)/2);
                punti3=Lung*(0.5+Ratio_Dist/2+(Ratio_Lung-Ratio_Dist)*exp(1i*(0:0.01:1)*2*pi)/2);
                punti4=Lung*[(1+Ratio_Lung)/2 1];
                punti5=Lung*(0.5+0.15*Ratio_Lung*exp(1i*(0:0.01:1)*2*pi)/2);
                ROTO_TRASLA({punti1; punti2; punti4; punti5},Opzioni,'Linea')
                Opzioni.Ramo_ii.Plot.Line_Type=[':' Opzioni.Ramo_ii.Plot.Line_Type];
                ROTO_TRASLA({punti3},Opzioni,'Linea')
                K_name=Opzioni.Ramo_ii.K_name;  Opzioni.Ramo_ii.K_name=' ';
                LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Blocco_Resistivo')
                Opzioni.Ramo_ii.K_name=K_name;
            case 'Effort'
                Ratio_Larg=0.35;            % Ratio_Lung = Diametro/Lung
                Ratio_Lung=Ratio_Larg;      % Ratio_Lung = Ratio_Larg
                punti1=Lung*[0 (1-Ratio_Larg)/2];
                punti2=Lung*(0.5+Ratio_Larg*exp(1i*(0:0.01:1)*2*pi)/2);
                punti3=Lung*[(1+Ratio_Larg)/2 1];
                punti4=Lung*(0.5+0.15*Ratio_Larg*exp(1i*(0:0.01:1)*2*pi)/2);
                ROTO_TRASLA({punti1; punti2; punti3; punti4},Opzioni,'Linea')
                LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Ingresso_Effort')
            case 'Flow'
                Ratio_Lung=0.4;             % Ratio_Lung = Spazio_occupato_dai_due_cerchi/Lung
                Ratio_Larg=Ratio_Lung;      % Ratio_Larg = Ratio_Lung
                Ratio_Dist=Ratio_Lung/3;    % Ratio_Dist = Distanza_tra_i_centri_dei_due_cerchi/Lung
                punti1=Lung*[0 (1-Ratio_Lung)/2];
                punti2=Lung*(0.5-Ratio_Dist/2+(Ratio_Lung-Ratio_Dist)*exp(1i*(0:0.01:1)*2*pi)/2);
                punti3=Lung*(0.5+Ratio_Dist/2+(Ratio_Lung-Ratio_Dist)*exp(1i*(0:0.01:1)*2*pi)/2);
                punti4=Lung*[(1+Ratio_Lung)/2 1];
                punti5=Lung*(0.5+0.15*Ratio_Lung*exp(1i*(0:0.01:1)*2*pi)/2);
                ROTO_TRASLA({punti1; punti2; punti3; punti4; punti5},Opzioni,'Linea')
                LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Ingresso_Flow')
        end
        DISEGNA_SCATOLA(P3,P4,P5,P6,Opzioni)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'rJ'                       % Inerzia J
        Ratio_Larg=0.5;             % Ratio_Larg = Larghezza_dell'elemento/Lung
        Ratio_Lung=0.5;             % Ratio_Lung = Lunghezza_dell'elemento/Lung
        punti1=Lung*([0 (1-Ratio_Lung)/2]);
        punti0=Ratio_Larg*exp(1i*(0:0.01:1)*2*pi)/2;
        punti2=Lung*(0.5+punti0);
        punti3=Lung*(0.5+0.5*punti0);
        punti4=Lung*([(1+Ratio_Lung)/2 1]);
        punti5=Lung*([(1-Ratio_Lung)/2 0.5+0.25*Ratio_Larg]);
        ROTO_TRASLA({punti1; punti2; punti3; punti4; punti5 },Opzioni,'Linea')
        patch(real(P5+e_jAngle*punti3),imag(P5+e_jAngle*punti3),[1 1 1]*0.7)
        LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Blocco_Effort')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case {'rE','rK'}                % Elasticit� E e Rigidit� K rotazionali
        Nr_spire=4;                 % Nr_spire = Numero_di_spire_dell'induttanza
        Ratio_Larg=0.4;             % Ratio_Larg = Larghezza_delle_spire/Lung
        Ratio_Lung=0.5;             % Ratio_Lung = Spazio_occupato_dalla_induttanza/Lung
        Nr_semigiri=2*Nr_spire+3;
        px=Ratio_Lung*(0:0.001:(2*Nr_spire+1)/Nr_semigiri);
        th=-pi-2*pi*px/(2*Ratio_Lung/(Nr_semigiri));
        reduce=(1:-1/(length(th)-1):0);
        punti1=Lung*[0 (1-Ratio_Lung)/2];
        punti2=Lung*((1-Ratio_Lung)/2+(Ratio_Lung*(1+reduce.*cos(th))/2+1i*Ratio_Larg*reduce.*sin(th)/2));
        punti3=Lung*[0.5 1];
        ROTO_TRASLA({punti1; punti2; punti3},Opzioni,'Linea')
        LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Blocco_Flow')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case {'rD','rB'}                % Coefficiente rotazionale d'attrito B e il suo reciproco D
        Ratio_Larg=0.4;             % Ratio_Larg = Larghezza_dell'elemento/Lung
        Ratio_Lung=0.2;             % Ratio_Lung = Lunghezza_dell'elemento/Lung
        a=Ratio_Lung; c=Ratio_Larg;
        punti0=([-a a a -a]+1i*[c c -c -c])/2;
        punti1=Lung*[0 0.5-a/2];
        punti2=Lung*(0.5+punti0);
        punti0=([0.9*a -a -a 0.9*a]+1i*0.8*[-c -c c c])/2;
        punti3=Lung*(0.5+punti0);
        punti4=Lung*[(1+Ratio_Lung)/2 1];
        ROTO_TRASLA({punti1; punti2; punti3; punti4 },Opzioni,'Linea')
        LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Blocco_Resistivo')
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% BLOCCHI IDRAULICI
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'iU'                       % Generatore IDRAULICO
        switch Opzioni.Ramo_ii.Out
            case 'Vuoto'
                Ratio_Lung=0.5;             % Ratio_Lung = Spazio_occupato_dai_due_triangoli/Lung
                Ratio_Larg=Ratio_Lung;      % Ratio_Larg = Ratio_Lung
                Ratio_Dist=Ratio_Lung/3;    % Ratio_Dist = Distanza_tra_i_centri_dei_due_triangoli/Lung
                punti1=Lung-Lung*[0 (1-Ratio_Lung)/2+(Ratio_Lung-Ratio_Dist)*cos(pi/3)/2];
                punti2=Lung-Lung*(0.5-Ratio_Dist/2-(Ratio_Lung-Ratio_Dist)*exp(1i*(-1:2/3:1)*pi)/2);
                punti3=Lung-Lung*(0.5+Ratio_Dist/2-(Ratio_Lung-Ratio_Dist)*exp(1i*(-1:2/3:1)*pi)/2);
                punti4=Lung-Lung*[(1+Ratio_Lung)/2 1];
                ROTO_TRASLA({punti1; punti3; punti4},Opzioni,'Linea')
                Opzioni.Ramo_ii.Plot.Line_Type=[':' Opzioni.Ramo_ii.Plot.Line_Type];
                ROTO_TRASLA({punti2},Opzioni,'Linea')
                K_name=Opzioni.Ramo_ii.K_name;  Opzioni.Ramo_ii.K_name=' ';
                LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Blocco_Resistivo')
                Opzioni.Ramo_ii.K_name=K_name;
            case 'Effort'
                Ratio_Lung=0.35;            % Ratio_Lung = Diametro/Lung
                Ratio_Larg=0.35;            % Ratio_Lung = Diametro/Lung
                punti1=Lung*[0 (1-Ratio_Larg)/2];
                punti2=Lung*(1+Ratio_Larg*exp(1i*(-1:2/3:1)*pi))/2;
                punti3=Lung*[(1+Ratio_Larg*cos(pi/3))/2 1];
                ROTO_TRASLA({punti1; punti2; punti3},Opzioni,'Linea')
                LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Ingresso_Effort')
            case 'Flow'
                Ratio_Lung=0.5;             % Ratio_Lung = Spazio_occupato_dai_due_triangoli/Lung
                Ratio_Larg=Ratio_Lung;      % Ratio_Larg = Ratio_Lung
                Ratio_Dist=Ratio_Lung/3;    % Ratio_Dist = Distanza_tra_i_centri_dei_due_triangoli/Lung
                punti1=Lung-Lung*[0 (1-Ratio_Lung)/2+(Ratio_Lung-Ratio_Dist)*cos(pi/3)/2];
                punti2=Lung-Lung*(0.5-Ratio_Dist/2-(Ratio_Lung-Ratio_Dist)*exp(1i*(-1:2/3:1)*pi)/2);
                punti3=Lung-Lung*(0.5+Ratio_Dist/2-(Ratio_Lung-Ratio_Dist)*exp(1i*(-1:2/3:1)*pi)/2);
                punti4=Lung-Lung*[(1+Ratio_Lung)/2 1];
                ROTO_TRASLA({punti1; punti2; punti3; punti4},Opzioni,'Linea')
                LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Ingresso_Flow')
        end
        DISEGNA_SCATOLA(P3,P4,P5,P6,Opzioni)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case {'iC','iK'}                % Capacit� Idraulica C e rigidezza igraulica K
        Ratio_Larg=0.5;             % Ratio_Larg = Larghezza_dell'elemento/Lung
        Ratio_Lung=0.7;             % Ratio_Lung = Lunghezza_dell'elemento/Lung
        punti1=Lung*([0 (1-Ratio_Lung)/2]);
        th=(0:0.01:1)*2*pi;
        punti0=(Ratio_Lung*sqrt(abs(cos(th))).*sign(cos(th))+1i*Ratio_Larg*sin(th))/2;
        punti2=Lung*(0.5+punti0);
        punti3=Lung*([(1+Ratio_Lung)/2 1]);
        punti4=Lung*(0.5+[punti0(51-24) punti0(51+24)]);
        ROTO_TRASLA({punti1; punti2; punti3; punti4},Opzioni,'Linea')
        punti5=Lung*(0.5+[punti0(51+24) punti0(51-24) punti0(51-24:51+24)]);
        patch(real(P5+e_jAngle*punti5),imag(P5+e_jAngle*punti5),[1 1 1]*0.7)
        LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Blocco_Effort')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'iL'                       % Induttanza Idraulica L
        Ratio_Larg=0.15;            % Ratio_Larg = Larghezza_dell'elemento/Lung
        Ratio_Lung=0.8;             % Ratio_Lung = Lunghezza_dell'elemento/Lung
        punti1=Lung*[0 (1-Ratio_Lung)/2];
        punti2=Lung*((1-Ratio_Lung+Ratio_Larg)/2-Ratio_Larg*exp(1i*(-0.5:0.01:0.5)*pi)/2);
        punti3=Lung*((1+Ratio_Lung-Ratio_Larg)/2-Ratio_Larg*exp(1i*(-1:0.01:1)*pi)/2);
        punti4=Lung*[(1+Ratio_Lung-Ratio_Larg)/2 1];
        punti5=Lung*([(1-Ratio_Lung+Ratio_Larg)/2 (1+Ratio_Lung-Ratio_Larg)/2]+1i*Ratio_Larg*[1 1]/2);
        punti6=Lung*([(1-Ratio_Lung+Ratio_Larg)/2 (1+Ratio_Lung-Ratio_Larg)/2]-1i*Ratio_Larg*[1 1]/2);
        ROTO_TRASLA({punti1; punti2; punti3; punti4; punti5; punti6},Opzioni,'Linea')
        LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Blocco_Flow')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case {'iR','iG'}                % Resistenza Idraulica R e Conduttanza Idraulica G
        Ratio_Larg=0.15;            % Ratio_Larg = Larghezza_dell'elemento/Lung
        Ratio_Lung=0.5;             % Ratio_Lung = Lunghezza_dell'elemento/Lung
        a=Ratio_Lung; c=Ratio_Larg;
        punti0=([-a -a a a -a a a -a]+1i*[-c c c -c -c c -c c])/2;
        punti1=Lung*[0 0.5-a/2];
        punti2=Lung*(0.5+punti0);
        punti3=Lung*[(1+Ratio_Lung)/2 1];
        ROTO_TRASLA({punti1; punti2; punti3},Opzioni,'Linea')
        LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Blocco_Resistivo')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% BLOCCHI VARI
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case '-D'                       % Diodo
        Ratio_Lung=0.35;            % Ratio_Lung = Diametro/Lung
        Ratio_Larg=0.35;            % Ratio_Lung = Diametro/Lung
        punti1=Lung-Lung*[0 (1-Ratio_Larg)/2];
        punti2=Lung-Lung*(1+Ratio_Larg*exp(1i*(-1:2/3:1)*pi))/2;
        punti3=Lung-Lung*[(1+Ratio_Larg*cos(pi/3))/2 1];
        punti4=Lung-Lung*(1+Ratio_Larg*[-1+0.8*1i -1-0.8*1i ])/2;
        ROTO_TRASLA({punti1; punti2; punti3; punti4},Opzioni,'Linea')
        LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Blocco_Resistivo')
    case '-/'                       % Switch
        Ratio_Lung=0.35;            % Ratio_Lung = Diametro/Lung
        Ratio_Larg=0.35;            % Ratio_Lung = Diametro/Lung
        punti1=Lung*[0 (1-Ratio_Larg)/2];
        punti2=Lung*((1-Ratio_Larg)/2+[0 0.3*exp(-1i*pi/6)]);
        punti3=Lung*[(1+Ratio_Larg/2)/2 1];
        ROTO_TRASLA({punti1; punti2; punti3},Opzioni,'Linea')
        LABELS(Ratio_Lung,Ratio_Larg,Opzioni,'Blocco_Resistivo')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function   DISEGNA_SCATOLA(P3,P4,P5,P6,Opzioni)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if Opzioni.Ramo_ii.Gemello==-1
    dxx=0.25;
    La=Opzioni.Ramo_ii.Plot.Lateral;
    PA=-abs(P3-P5)/2+dxx*1i;
    PB=PA-1i*(2*dxx+La);
    PD=abs(P6-P5)+abs(P6-P4)/2+dxx*1i;
    PC=PD-1i*(2*dxx+La);
    Opzioni.Ramo_ii.Plot.Line_Type=[':' Opzioni.Grafico.Line_Type];
    ROTO_TRASLA({[PA PB PC PD PA]},Opzioni,'Linea') 
    Opzioni.Ramo_ii.Plot.Line_Type=['.' Opzioni.Grafico.Line_Type];
    ROTO_TRASLA({PB},Opzioni,'Linea') 
    LABELS(1,1,Opzioni,'Connessione')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  LABELS(Ratio_Lung,Ratio_Larg,Opzioni,Tipo_di_Label)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Lung=Opzioni.Lung; P5=Opzioni.P5; Angle=Opzioni.Angle; Ramo_ii=Opzioni.Ramo_ii;
if strcmp(Opzioni.Ramo_ii.Plot.Show_Labels,'Si')
    switch Tipo_di_Label
        case 'Freccia_Flow'          % Freccia Flow
            Lung_max=Lung*0.3; if Lung_max>0.25; Lung_max=0.25; end 
            Lung_min=Lung*0.05; if Lung_min<0.03; Lung_min=0.03; end 
            P1=Lung*0+Ramo_ii.Plot.E_up_down*1i*(Lung_max);
            P2=Lung*0+Ramo_ii.Plot.E_up_down*1i*(Lung_min);
            if Ramo_ii.Plot.K_up_down==-1
                P12=P1;P1=P2;P2=P12;
            end
            ROTO_TRASLA(FRECCIA(P1,P2,0.06,0.06),Opzioni,'Freccia')
            Punto=-Lung*0.05+Ramo_ii.Plot.E_up_down*1i*(Lung_max+Lung_min)/2;
            ROTO_TRASLA_TESTO(Punto,char(Ramo_ii.K_name),Opzioni,'Stato')
        case 'Freccia_Effort'
            P1=Lung*0.95;
            P2=Lung*0.05;
            ROTO_TRASLA(FRECCIA(P1,P2,0.06,0.06),Opzioni,'Freccia')
            Punto=Lung*0.5+Ramo_ii.Plot.E_up_down*1i*(0+0.01);
            ROTO_TRASLA_TESTO(Punto,char(Ramo_ii.E_name),Opzioni,'Stato')
        case 'Tratteggio_con_frecce'
            P1=Lung*0.95+Ramo_ii.Plot.E_up_down*1i*(Lung*0.05);
            P2=Lung*0.05+Ramo_ii.Plot.E_up_down*1i*(Lung*0.05);
            ROTO_TRASLA(FRECCIA(P1,P2,0.06,0.06),Opzioni,'Freccia')
            Punto=Lung*0.5+Ramo_ii.Plot.E_up_down*1i*(Lung*0.06);
            ROTO_TRASLA_TESTO(Punto,char(Ramo_ii.E_name),Opzioni,'Stato')
            %
            Lung_max=Lung*0.3; if Lung_max>0.25; Lung_max=0.25; end 
            Lung_min=Lung*0.05; if Lung_min<0.03; Lung_min=0.03; end 
            P1=Lung*0+Ramo_ii.Plot.E_up_down*1i*(Lung_max);
            P2=Lung*0+Ramo_ii.Plot.E_up_down*1i*(Lung_min);
            if Ramo_ii.Plot.K_up_down==-1
                P12=P1;P1=P2;P2=P12;
            end
            ROTO_TRASLA(FRECCIA(P1,P2,0.06,0.06),Opzioni,'Freccia')
            Punto=-Lung*0.05+Ramo_ii.Plot.E_up_down*1i*(Lung_max+Lung_min)/2;
            ROTO_TRASLA_TESTO(Punto,char(Ramo_ii.K_name),Opzioni,'Stato')
        case 'Ingresso_Effort'
            if strcmp(Opzioni.Ramo_ii.Plot.Show_X,'Si')
                Lat=Lung*Ratio_Larg/2;
                P1=Lung*0.75+Ramo_ii.Plot.E_up_down*1i*(Lat+0.03);
                P2=Lung*0.25+Ramo_ii.Plot.E_up_down*1i*(Lat+0.03);
                ROTO_TRASLA(FRECCIA(P1,P2,0.06,0.06),Opzioni,'Freccia')
                Punto=Lung*0.5+Ramo_ii.Plot.E_up_down*1i*(Lat+0.05);
                ROTO_TRASLA_TESTO(Punto,char(Ramo_ii.E_name),Opzioni,'Stato')
            end
            if strcmp(Opzioni.Ramo_ii.Plot.Show_Y,'Si')
                ROTO_TRASLA(FRECCIA(-Opzioni.Ramo_ii.Pow_In*0.001,0,0.06,0.06),Opzioni,'Freccia')
                Punto=Ramo_ii.Plot.F_up_down*1i*0.05;
                ROTO_TRASLA_TESTO(Punto,char(Ramo_ii.F_name),Opzioni,'Uscita')
            end
        case 'Ingresso_Flow'
            if strcmp(Opzioni.Ramo_ii.Plot.Show_X,'Si')
                ROTO_TRASLA(FRECCIA(-Opzioni.Ramo_ii.Pow_In*0.001,0,0.06,0.06),Opzioni,'Freccia')
                Punto=Ramo_ii.Plot.F_up_down*1i*0.05;
                ROTO_TRASLA_TESTO(Punto,char(Ramo_ii.F_name),Opzioni,'Stato')
            end
            if strcmp(Opzioni.Ramo_ii.Plot.Show_Y,'Si')
                Lat=Lung*Ratio_Larg/2;
                P1=Lung*0.75+Ramo_ii.Plot.E_up_down*1i*(Lat+0.03);
                P2=Lung*0.25+Ramo_ii.Plot.E_up_down*1i*(Lat+0.03);
                ROTO_TRASLA(FRECCIA(P1,P2,0.06,0.06),Opzioni,'Freccia')
                Punto=Lung*0.5+Ramo_ii.Plot.E_up_down*1i*(Lat+0.05);
                ROTO_TRASLA_TESTO(Punto,char(Ramo_ii.E_name),Opzioni,'Uscita')
            end
        case 'Blocco_Effort'
            Lat=Lung*Ratio_Larg/2;
            Punto=Lung*(1-Ratio_Lung)/4+Ramo_ii.Plot.K_up_down*1i*(Lat/4+0.015);
            ROTO_TRASLA_TESTO(Punto,char(Ramo_ii.K_name),Opzioni,'Parametro_K')
            if strcmp(Opzioni.Ramo_ii.Plot.Show_X,'Si')
                P1=Lung*0.75+Ramo_ii.Plot.E_up_down*1i*(Lat+0.05);
                P2=Lung*0.25+Ramo_ii.Plot.E_up_down*1i*(Lat+0.05);
                ROTO_TRASLA(FRECCIA(P1,P2,0.06,0.06),Opzioni,'Freccia')
                Punto=Lung*0.5+Ramo_ii.Plot.E_up_down*1i*(Lat+0.07);
                ROTO_TRASLA_TESTO(Punto,char(Ramo_ii.E_name),Opzioni,'Stato')
            end
            if strcmp(Opzioni.Ramo_ii.Plot.Show_Y,'Si')
                ROTO_TRASLA(FRECCIA(-0.001,0,0.06,0.06),Opzioni,'Freccia')
                Punto=Ramo_ii.Plot.F_up_down*1i*0.05;
                ROTO_TRASLA_TESTO(Punto,char(Ramo_ii.F_name),Opzioni,'Uscita')
            end
        case 'Blocco_Flow'
            Lat=Lung*Ratio_Larg/2;
            Punto=Lung*0.5+Ramo_ii.Plot.K_up_down*1i*(Lat+0.015);
            ROTO_TRASLA_TESTO(Punto,char(Ramo_ii.K_name),Opzioni,'Parametro_K')
            if strcmp(Opzioni.Ramo_ii.Plot.Show_X,'Si')
                ROTO_TRASLA(FRECCIA(-0.001,0,0.06,0.06),Opzioni,'Freccia')
                Punto=Ramo_ii.Plot.F_up_down*1i*0.05;
                ROTO_TRASLA_TESTO(Punto,char(Ramo_ii.F_name),Opzioni,'Stato')
            end
            if strcmp(Opzioni.Ramo_ii.Plot.Show_Y,'Si')
                P1=Lung*0.75+Ramo_ii.Plot.E_up_down*1i*(Lat+0.05);
                P2=Lung*0.25+Ramo_ii.Plot.E_up_down*1i*(Lat+0.05);
                ROTO_TRASLA(FRECCIA(P1,P2,0.06,0.06),Opzioni,'Freccia')
                Punto=Lung*0.5+Ramo_ii.Plot.E_up_down*1i*(Lat+0.07);
                ROTO_TRASLA_TESTO(Punto,char(Ramo_ii.E_name),Opzioni,'Uscita')
            end
        case 'Blocco_Resistivo'
            Lat=Lung*Ratio_Larg/2;
            Punto=Lung*0.5+Ramo_ii.Plot.K_up_down*1i*(Lat+0.02);
            ROTO_TRASLA_TESTO(Punto,char(Ramo_ii.K_name),Opzioni,'Parametro_K')
            if strcmp(Opzioni.Ramo_ii.Plot.Show_X,'Si')
                if strcmp(Ramo_ii.Out,'Effort')
                    P1=Lung*0.75+Ramo_ii.Plot.E_up_down*1i*(Lat+0.05);
                    P2=Lung*0.25+Ramo_ii.Plot.E_up_down*1i*(Lat+0.05);
                    ROTO_TRASLA(FRECCIA(P1,P2,0.06,0.06),Opzioni,'Freccia')
                    Punto=Lung*0.5+Ramo_ii.Plot.E_up_down*1i*(Lat+0.07);
                    ROTO_TRASLA_TESTO(Punto,char(Ramo_ii.E_name),Opzioni,'Stato')
                elseif strcmp(Ramo_ii.Out,'Flow')
                    ROTO_TRASLA(FRECCIA(-0.001,0,0.06,0.06),Opzioni,'Freccia')
                    Punto=Ramo_ii.Plot.F_up_down*1i*0.05;
                    ROTO_TRASLA_TESTO(Punto,char(Ramo_ii.F_name),Opzioni,'Stato')
                end
            end
            if strcmp(Opzioni.Ramo_ii.Plot.Show_Y,'Si')
                if strcmp(Ramo_ii.Out,'Flow')
                    P1=Lung*0.75+Ramo_ii.Plot.E_up_down*1i*(Lat+0.05);
                    P2=Lung*0.25+Ramo_ii.Plot.E_up_down*1i*(Lat+0.05);
                    ROTO_TRASLA(FRECCIA(P1,P2,0.06,0.06),Opzioni,'Freccia')
                    Punto=Lung*0.5+Ramo_ii.Plot.E_up_down*1i*(Lat+0.07);
                    ROTO_TRASLA_TESTO(Punto,char(Ramo_ii.E_name),Opzioni,'Uscita')
                elseif strcmp(Ramo_ii.Out,'Effort')
                    ROTO_TRASLA(FRECCIA(-0.001,0,0.06,0.06),Opzioni,'Freccia')
                    Punto=Ramo_ii.Plot.F_up_down*1i*0.05;
                    ROTO_TRASLA_TESTO(Punto,char(Ramo_ii.F_name),Opzioni,'Uscita')
                end
            end
        case 'Connessione'
            Opzioni.Ramo_ii.Plot.Font_K=9;
            Punto=Lung-1i*Ramo_ii.Plot.Lateral/2;
            if ismember(Opzioni.Ramo_ii.TR_o_GY,'T_G')
                Str_Inv = char(CALCOLA_PARAMETRO_KN_DI_T_G(Opzioni.Ramo_ii));
                ROTO_TRASLA_TESTO(Punto,[Opzioni.Ramo_ii.TR_o_GY '=' Str_Inv],Opzioni,'Connessione')
            else
                beep; disp('Valore sbagliato della variabile TR_o_GY')
            end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  ROTO_TRASLA(punti,Opzioni,Tipo_di_Linea)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
P5=Opzioni.P5; Angle=Opzioni.Angle;
if nargin==2
    Tipo_di_Linea='Linea';
end
switch Tipo_di_Linea
    case 'Linea'   % Linee di tipo "Grafico"
        Line_Type=Opzioni.Ramo_ii.Plot.Line_Type;
        Line_Width=Opzioni.Ramo_ii.Plot.Line_Width;
    case 'Freccia'   % Linee di tipo "Frecce"
        Line_Type=Opzioni.Ramo_ii.Plot.Frecce_Type;
        Line_Width=Opzioni.Ramo_ii.Plot.Frecce_Width;
end
for ii=(1:max(size(punti)))
    pnt=P5+Angle*punti{ii};
    plot(real(pnt),imag(pnt),Line_Type,'Linewidth',Line_Width)
    hold on
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  ROTO_TRASLA_TESTO(Punto,String,Opzioni,Tipo_di_Testo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
P5=Opzioni.P5; Angle=Opzioni.Angle;
String_Text=String;
if strcmp(Opzioni.Grafico.Underscore,'No')
    String_Text=strrep(String_Text,'_','');
end
FontSize = 10;
FontColor  = 'k';
switch Tipo_di_Testo
    case 'Nodo'
        Show_Testo=Opzioni.Grafico.Show_Nomi_Nodi;
        FontSize = Opzioni.Grafico.Font_Nodi;
        FontColor = Opzioni.Grafico.Color_Nodi;
    case 'Ramo'
        Show_Testo=Opzioni.Grafico.Show_Nomi_dei_Rami;
        FontSize = Opzioni.Grafico.Font_Nomi_dei_Rami;
        FontColor = Opzioni.Grafico.Color_Nomi_dei_Rami;
    case {'Parametro_K','Connessione'}
        Show_Testo=Opzioni.Ramo_ii.Plot.Show_K;
        FontSize = Opzioni.Ramo_ii.Plot.Font_K;
        FontColor  = Opzioni.Ramo_ii.Plot.Color_K;
    case 'Stato'
        Show_Testo=Opzioni.Ramo_ii.Plot.Show_X;
        FontSize = Opzioni.Ramo_ii.Plot.Font_X;
        FontColor  = Opzioni.Ramo_ii.Plot.Color_X;
    case 'Uscita'
        Show_Testo=Opzioni.Ramo_ii.Plot.Show_Y;
        FontSize = Opzioni.Ramo_ii.Plot.Font_Y;
        FontColor  = Opzioni.Ramo_ii.Plot.Color_Y;
end
if strcmp(Show_Testo,'Si')
    New_Punto=P5+Angle*Punto;
    h=text(real(New_Punto),imag(New_Punto),String_Text,'FontSize',FontSize,'Color',FontColor);
    %%%% Testo latex per utilizzare il comando "psfrag"
    [orz, ver] = POSIZIONE_TESTO(h,Punto,Angle,Tipo_di_Testo);
    if strcmp(Opzioni.Grafico.Show_Psfrag,'Si')
        MOSTRA_STRINGA_PSFRAG(String,String_Text,orz,ver)
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [orz, ver] = POSIZIONE_TESTO(h,Punto,Angle,Tipo_di_Testo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(h,'HorizontalAlignment','center'); orz='c';
set(h,'VerticalAlignment','middle'); ver='c';
sotto=imag(Punto);
if sotto<=0
    top='top';
    bottom='bottom';
    left='left';
    right='right';
else
    top='bottom';
    bottom='top';
    left='right';
    right='left';
end
dot1=[1 -1 ]*[real(Angle) imag(Angle) ]';
dot2=[1  1 ]*[real(Angle) imag(Angle) ]';
if not(strcmp(Tipo_di_Testo,'Connessione'))
    if (dot1>=0)&&(dot2>=0)
        set(h,'VerticalAlignment',top)
        if strcmp(top,'top'); ver='t'; else ver='b';  end;
    end
    if (dot1>=0)&&(dot2<=0)
        set(h,'HorizontalAlignment',right)
        if strcmp(right,'right'); orz='r'; else orz='l';  end;
    end
    if (dot1<=0)&&(dot2<=0)
        set(h,'VerticalAlignment',bottom)
        if strcmp(bottom,'top'); ver='t'; else ver='b';  end;
    end
    if (dot1<=0)&&(dot2>=0)
        set(h,'HorizontalAlignment',left)
        if strcmp(left,'right'); orz='r'; else orz='l';  end;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Punti = FRECCIA(P1,P2,rx,ry)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  disegna una frecccia nel punto P2 nella direzione del vettore P2-P1
%  La freccia avra' lunghezza rx e ry nelle due direzioni x  y.
x0=real(P1);  y0=imag(P1);
x=real(P2);   y=imag(P2);
dx=(x-x0)/rx; dy=(y-y0)/ry;
dxy=sqrt(dx^2+dy^2);
fx=-dx/dxy;   fy=-dy/dxy;
rotpiu=[rx,0;0,ry]*[cos(pi/6), -sin(pi/6); sin(pi/6), cos(pi/6) ]*[fx,fy]';
rotmeno=[rx,0;0,ry]*[cos(pi/6), sin(pi/6); -sin(pi/6), cos(pi/6) ]*[fx,fy]';
Punti1=[x0,x]+1i*[y0,y];
Punti2=[x,x+rotpiu(1)]+1i*[y,y+rotpiu(2)];
Punti3=[x,x+rotmeno(1)]+1i*[y,y+rotmeno(2)];
Punti={Punti1; Punti2; Punti3};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Rami_Input = TOGLI_LE_COPPIE_pm_N(Rami_Input)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%  ELIMINA LE COPPIE (+N,-N) ALL'INTERNO DI "Rami_Input"
Ind=0;
while not(isempty(Ind))
    [~,Ind,~]=intersect(Rami_Input,-Rami_Input);
    Rami_Input=Rami_Input(setdiff(1:length(Rami_Input),Ind));
end
if isempty(Rami_Input); 
    Rami_Input=[]; 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [Par1,Par2] = SEPARA(Parametro,Carattere)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ind=find(Parametro==Carattere);
if not(isempty(ind))
    Par1=Parametro(1:ind(1)-1);
    Par2=Parametro(ind(1)+1:end);
else
    Par1=Parametro;  Par2='';
    % beep; disp(['Il carattere ' Carattere 'non � presente nella stringa "' Parametro '"'])
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function   SHOW_RAMO(Ramo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ramo.K_name=char(Ramo.K_name);
Ramo.Q_name=char(Ramo.Q_name);
Ramo.E_name=char(Ramo.E_name);
Ramo.F_name=char(Ramo.F_name);
disp(Ramo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function   Prima_Riga = ANALIZZA_CB(Riga)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sostituisce i blocchi 'CB' e 'BC' con blocchi 'bT','bG','bTi'e'bGi'
Tipo_di_CB='bT';                        % Valore di Default nel caso di errore 
Ind=[find(Riga==',') length(Riga)+1];
Prima_Riga  = Riga(1:Ind(3)-1);         % Prima_Riga = "Tipo_di_Blocco,Nodo_From,Nodo_To"
for jj=3:2:(length(Ind)-1)              % Ci sono 2 virgole per ogni parametro
    switch Riga(Ind(jj)+1:Ind(jj+1)-1)  % Sigla del Parametro
        case 'Kn'     
            % Se Kn � definito in modo errato il "CB" viene sostituito da "bT"
            Stringa=Riga(Ind(jj+1)+1:Ind(jj+2)-1);
            Ind_eq=find(Stringa=='=');
            Ind_as=find(Stringa=='*');
            Par_Kn=Stringa(Ind_eq+1:Ind_as-1);
            New_Stringa=[Stringa(1:Ind_eq) 'Kn' Stringa(Ind_as:end)];
            switch New_Stringa
                case {'E1=Kn*E2','F2=Kn*F1'}
                    Tipo_di_CB='bT';
                    Prima_Riga  =[Prima_Riga   ',Kn,' Par_Kn ];
                    Str_Dir=',Dir,Si';
                case {'E1=Kn*F2','E2=Kn*F1'}
                    Tipo_di_CB='bG';
                    Prima_Riga  =[Prima_Riga   ',Kn,' Par_Kn ];
                    Str_Dir=',Dir,Si';
                case {'E2=Kn*E1','F1=Kn*F2'}
                    Tipo_di_CB='bT';
                    Prima_Riga  =[Prima_Riga   ',Kn,' Par_Kn ];
                    Str_Dir=',Dir,No';
                case {'F2=Kn*E1','F1=Kn*E2'}
                    Tipo_di_CB='bG';
                    Prima_Riga  =[Prima_Riga   ',Kn,' Par_Kn ];
                    Str_Dir=',Dir,No';
                otherwise
                    beep;
                    disp(['Il parametro "' 'Kn,' Stringa '" viene tolto perch� non corretto!'])
                    disp('Il "CB" viene sostituito dal blocco "bT"')
                    disp(' ')
            end
        otherwise
            Prima_Riga  =[Prima_Riga   ',' Riga(Ind(jj)+1:Ind(jj+2)-1) ];
    end
end
Prima_Riga  =[Tipo_di_CB Prima_Riga(3:end) Str_Dir ];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Sistema = SOSTITUZIONE_DEI_METABLOCCHI(Sistema)
%%% VARIABILI IN INGRESSO:
%   Sistema.Schema_ASCII_Base       ->  Schema NON filtrato
%%% VARIABILI IN USCITA:
%   Sistema.Schema_ASCII            ->  Schema filtrato
%   Sistema.Lista_RAMI  
%   Sistema.Lista_Nodi
%%% FUNZIONI SVOLTE:
% -> VENGONO TOLTI I COMANDI CHE NON POSSONO ESSERE UTILIZZATI DALL'UTENTE ('Ge','T_G') 
% -> I RAMI {'bTi','bGi'} VENGONO CONVERTITI -> {'bT','bG'}+',Dir,No'
% -> AD OGNI NUOVO NODO VIENE ASSOCIATA UNA POSIZIONE FISICA NEL GRAFICO  
% -> AD OGNI NUOVO NODO E AD OGNI RAMO VIENE ASSOCIATO UN DOMINIO ENERGETICO 
% -> RAMI TRASFORMATORI 'bT' E GIRATORI 'bG' VENGONO SDOPPIATI IN DUE RAMI GEMELLI
% -> I RAMI INGRESSO DI TIPO EFFORT VENGONO CONVERTITI -> {'eU','mU','rU','iU'}+',Out,Effort'
% -> I RAMI INGRESSO DI TIPO FLOW VENGONO CONVERTITI -> {'eU','mU','rU','iU'}+',Out,Flow'
% -> SI VERIFICA LA CONSISTENZA DEI VARI AMBITI ENERGETICI ->   Domini_Omogenei='Si';
% -> SOSTITUISCE I BLOCCHI 'CB' e 'BC' CON BLOCCHI 'bT','bG','bTi' e 'bGi' 
% -> I TRASFORMATORI E GIRATORI VENGONO CONVERTITI IN INGRESSI CONTROLLATI 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Schema_ASCII_Base=Sistema.Schema_ASCII_Base;
Schema_ASCII={};
Lista_Nodi_Predefiniti=Sistema.Lista_Nodi_Predefiniti;
% 
Nr_Linee_ASCII=size(Schema_ASCII_Base,1);  	% Ogni riga dello schema definisce un ramo
%%% CAMPI DELLA STRUTTURA "Lista_Nodi"
Lista_Nodi(1).Nome=[];                      % Ad ogni nodo viene assegnato un nome numerico
Lista_Nodi(1).Nome_Vero={};                 % Ad ogni nodo viene assegnato un nome vero di tipo ASCII
Lista_Nodi(1).Posizione=[];                 % Posizione del nodo all'interno dello schema
Lista_Nodi(1).Dominio=' ';                  % Dominio (ambito energetico) del nodo 
%%% SI ANALIZZANO IN SEQUENZA LE RIGHE DELLA STRUTTURA "Schema_ASCII_Base"
hh_Nodo=1;                                  % Indice dell'ultimo nome assegnato ad un nodo
ii_Ramo=1;                                  % Indice di Ramo
for ii_ASCII=1:Nr_Linee_ASCII               % La virgola "," separa i parametri
    Riga=Schema_ASCII_Base(ii_ASCII,:);
    %%% VENGONO TOLTI I COMANDI CHE NON POSSONO ESSERE UTILIZZATI DALL'UTENTE
    Ind=[find(Riga==',') length(Riga)+1];
    Prima_Riga  = Riga(1:Ind(3)-1);         % Prima_Riga = "Tipo_di_Blocco,Nodo_From,Nodo_To" 
    Nr_Virgole=length(Ind);
    for jj=3:2:(Nr_Virgole-1)               % Ci sono 2 virgole per ogni parametro
        switch Riga(Ind(jj)+1:Ind(jj+1)-1)  % Sigla del Parametro
            case {'Ge','T_G'}       % 'Ge'=Ramo gemello; 'T_G'=Trasformatori o Giratori;
                %%% Questi comandi INTERNI, se presenti, vengono tolti da "Prima_Riga"
            otherwise
            Prima_Riga  =[Prima_Riga   ',' Riga(Ind(jj)+1:Ind(jj+2)-1)];
        end
    end
    %%% I RAMI {'bTi','bGi'} VENGONO CONVERTITI -> {'bT','bG'}+',Dir,No'  
    Prima_Riga=deblank(Prima_Riga);
    switch Prima_Riga(1:Ind(1)-1)
        case {'bTi','bGi'}
            % Un ramo e' INVERSO quando si ha: Diretto='No' 
            Prima_Riga  =[Prima_Riga(1:2) Prima_Riga(4:end) ',Dir,No' ];
        case {'bT','bG'}
            % Un ramo e' DIRETTO quando si ha: Diretto='Si' 
            Prima_Riga  =[Prima_Riga(1:end) ',Dir,Si' ];
        case {'CB','BC'}
            % Sostituisce i blocchi 'CB' e 'BC' con blocchi 'bT','bG','bTi' e 'bGi' 
            Prima_Riga = ANALIZZA_CB(Prima_Riga);
    end
    %%% VENGONO ESTRATTI I PARAMETRI DEL RAMO SEPARATI DA VIRGOLE
    [Lista_Parametri, Nr_Parametri] = ESTRAI_PARAMETRI(Prima_Riga);
    if (Nr_Parametri<3)||(mod(Nr_Parametri,2)==0)                 
        disp(['Errore! Ramo non correttamente definito : ' Schema_ASCII_Base(ii_ASCII,:)])
        break     % Il ramo deve avere un numero N dispari di parametri con N>=3 
    end
    %%% Il primo parametro identifica il "tipo" di ramo 
    Nome_Ramo=Lista_Parametri{1}{1};        % Nome_Ramo = Sigla del blocco: e' il primo dei parametri    
    Dominio_del_Ramo=' ';                   % Indica il dominio energetico del ramo: ' '='Non_definito'
    % I rami che hanno un dominio energetico 'Non_definito' sono quello di natura "grafica" 
    if ismember(Nome_Ramo(1),'emri')        % Solo i domini 'emri' sono ammessi
        Dominio_del_Ramo=Nome_Ramo(1);      % Il primo carattere di Nome_Ramo identifica il dominio energetico
    end
    %%% AD OGNI NUOVO NODO VIENE ASSOCIATA UNA POSIZIONE FISICA NEL GRAFICO
    for jj=2:3                                  % Si analizzano in sequenza i nodi "From" (2) e "To" (3)
        Nomi_Veri_jj=Lista_Parametri{jj};
        Nr_Nodi_jj=length(Nomi_Veri_jj);        % I nodi possono essere doppi 
        Nome_Nodi_jj=zeros(1,Nr_Nodi_jj);       % Nome dei nodi (eventualmente doppi)
        for kk=1:Nr_Nodi_jj                     % Gestisce i nodi multipli
            % Ad ogni nodo A puo' essere associta una posizione specifica: A=(x+1i*y) 
            % La posizione del nodo A viene definita utilizzando un numero complesso: x+1i*y 
            [Nomi_Veri_jj{kk}, Posizione] = SEPARA(Nomi_Veri_jj{kk},'=');
            [Nome_gia_presente,Pos]=ismember(Nomi_Veri_jj{kk},[Lista_Nodi.Nome_Vero]);
            if Nome_gia_presente                % Il nome "interno" del nodo coindice con  
                Nome_Nodi_jj(kk) = Pos;         % ... la posizione Pos che il nome "esterno" occupa
                                                % ... all'interno del vettore "Lista_Nodi.Nome_Vero"
                if not(isempty(Posizione))
                    Lista_Nodi(Pos).Posizione = eval(Posizione);    % La posizione del nodo viene ridefinita
                end
                Dominio_del_Nodo=Lista_Nodi(Pos).Dominio;           % Dominio del nodo che esiste gia'
                if ismember(Dominio_del_Ramo,'emri')&&(ismember(Dominio_del_Nodo,'emri'))
                    if Dominio_del_Ramo~=Dominio_del_Nodo
                        %%% SE IL RAMO E IL NODO NON HANNO LO STESSO DOMINIO ENERGETICO 
                        Stringa=['Il ramo ' num2str(ii_Ramo) '-' Nome_Ramo ' e il nodo ' ...
                                  num2str(Pos) '-' Dominio_del_Nodo ...
                                 ' appartengono a domini energetici diversi!'];
                        SHOW_ERRORE(Sistema,Stringa)
                    end
                elseif ismember(Dominio_del_Ramo,'emri')
                    %%% IL DOMINIO DEI RAMI ENERGETICI VIENE ASSEGNATO AL NODO
                    Lista_Nodi(Pos).Dominio =Dominio_del_Ramo;
                end
            else
                %%% SE IL NODO E' NUOVO ...
                [Nodo_gia_definito,Pos]=ismember(Nomi_Veri_jj{kk},[Lista_Nodi_Predefiniti.Nome]);
                if Nodo_gia_definito                % La posizione del Nodo � gi� stata definita
                    Posizione=Lista_Nodi_Predefiniti(Pos).Posizione;
                end
                Nome_Nodi_jj(kk) = hh_Nodo;                         % Nomi interni: numeri crescenti 
                Lista_Nodi(hh_Nodo).Nome_Vero = Nomi_Veri_jj(kk);   % Nome vero del nodo
                Lista_Nodi(hh_Nodo).Nome = hh_Nodo;                 % Nome numerico del nodo
                %%% SI ASSSEGNA UN VALORE ALLA POSIZIONE DEL NUOVO NODO: 'Inf'='Posizione_non_definita' 
                if not(isempty(Posizione))
                    Lista_Nodi(hh_Nodo).Posizione = eval(Posizione);% Posizione precisa del nodo
                else
                    Lista_Nodi(hh_Nodo).Posizione = Inf;            % Posizione del nodo non definita
                end
                %%% IL DOMINO DEL NUOVO NODO E' INIZIALMENTE 'Non_definito' 
                Lista_Nodi(hh_Nodo).Dominio =' ';                   
                if ismember(Nome_Ramo(1),'emri')
                    %%% IL DOMINIO DEL RAMO ENERGETICO VIENE DATO AL NODO
                    Lista_Nodi(hh_Nodo).Dominio =Nome_Ramo(1);      
                end
                hh_Nodo = hh_Nodo+1;
            end
        end
        if jj==2
            From = Nome_Nodi_jj;            % Nome interno dei nodi "From"
        elseif jj==3 
            To = Nome_Nodi_jj;              % Nome interno dei nodi "To"
        end
    end
    %%% CAMPI DELLA VARIABILE "Ramo_ii"
    Ramo_ii.Nome_Ramo=Nome_Ramo;            % Sigla del ramo
    Ramo_ii.Dominio=Dominio_del_Ramo;   	% Dominio Energetico del ramo
    Ramo_ii.From=From(1);                   % Numero interno del nodo di partenza
    Ramo_ii.To=To(1);                       % Numero interno del nodo di arrivo
    %%% LISTA DEI RAMI DELLO SCHEMA 
    Lista_RAMI(ii_Ramo)=Ramo_ii;            % Lista dei nuovi rami dello schema
    %%%% GESTIONE DEI METABLOCCHI
    switch Nome_Ramo
        %%% I RAMI TRASFORMATORI 'bT' E GIRATORI 'bG' VENGONO SDOPPIATI IN
        %%% ... DUE RAMI GEMELLI DI TIPO INGRESSO. L'AMBITO ENERGETICO DEI DUE
        %%% ... INGRESSO E' QUELLO DEGLI ELEMENTI FISICI A CUI I DUE INGRESSI SONO COLLEGATI  
        case {'bT','bG'}
            Prima_Riga=Nome_Ramo;
            Seconda_Riga=Nome_Ramo;
            %%% I parametri doppi [a;b] vengono riscritti sulla Prima_Riga (a) e Seconda_Riga (b) 
            for jj=2:Nr_Parametri
                Prima_Riga  =[Prima_Riga   ',' Lista_Parametri{jj}{1}];
                Seconda_Riga=[Seconda_Riga ',' Lista_Parametri{jj}{length(Lista_Parametri{jj})}];
            end
            Ind=find(Prima_Riga==',');                              % Posizione dei separatori "," sulla prima riga
            % Dopo i primi tre parametri viene inserito uno Shift di default: ',Sh,0.4'
            Prima_Riga  =[Prima_Riga(1:Ind(3)-1)   ',Sh,' num2str(0.4) Prima_Riga(Ind(3):end)];
            Prima_Riga  =[Prima_Riga   ',Ge,' num2str(+1) ];        % Il ramo gemello e' il successivo (+1)
            Prima_Riga  =[Prima_Riga   ',T_G,' Nome_Ramo(2) ];      % Trasformatore o Giratore
            Prima_Riga  =[Prima_Riga   ',Pin,' num2str(+1) ];       % Potenza entrante (+1) nel primo ramo
            ii_Ramo=ii_Ramo+1;
            Ind=find(Seconda_Riga==',');                            % Posizione dei separatori "," sulla seconda riga
            % Dopo i primi tre parametri viene inserito uno Shift di default: ',Sh,-0.4'
            Seconda_Riga  =[Seconda_Riga(1:Ind(3)-1)   ',Sh,' num2str(-0.4) Seconda_Riga(Ind(3):end)];
            Seconda_Riga  =[Seconda_Riga   ',Ge,' num2str(-1) ];    % Il ramo gemello e' il precedente (-1)
            Seconda_Riga  =[Seconda_Riga   ',II,' num2str(-1) ];    % Il ramo e' parallelo a quello precedente (-1)
            Seconda_Riga  =[Seconda_Riga   ',T_G,' Nome_Ramo(2) ];  % Trasformatore o Giratore
            Seconda_Riga  =[Seconda_Riga   ',Pin,' num2str(-1) ];   % Potenza uscente (-1) nel ramo gemello
            %%% IL DOMINIO DEI TRASFORMATORI E DEI GIRATORI NON E' DEFINITO 
            Lista_RAMI(ii_Ramo)=Lista_RAMI(ii_Ramo-1);
            Lista_RAMI(ii_Ramo).From=From(2);
            Lista_RAMI(ii_Ramo).To=To(2);
            Schema_ASCII{ii_Ramo-1}=Prima_Riga;
            Schema_ASCII{ii_Ramo}=Seconda_Riga;
        case {'eV','mV','rW','iP'}
            %%% I RAMI INGRESSO DI TIPO EFFORT VENGONO CONVERTITI -> {'eU','mU','rU','iU'}+',Out,Effort'
            Prima_Riga  =[Prima_Riga   ',Out,Effort'  ];
            Prima_Riga(2) ='U';
            Schema_ASCII{ii_Ramo}=Prima_Riga;
        case {'eI','mF','rT','iQ'}
            %%% I RAMI INGRESSO DI TIPO FLOW VENGONO CONVERTITI -> {'eU','mU','rU','iU'}+',Out,Flow'
            Prima_Riga  =[Prima_Riga   ',Out,Flow'  ];
            Prima_Riga(2) ='U';
            Schema_ASCII{ii_Ramo}=Prima_Riga;
        otherwise
            %%% TUTTI GLI ALTRI RAMI VENGONO LASCIATI INVERIATI
            Schema_ASCII{ii_Ramo}=Prima_Riga;
    end
    ii_Ramo=ii_Ramo+1;
end
Nr_dei_Rami=ii_Ramo-1;
%%%%%%  SI VERIFICA LA CONSISTENZA DEI VARI AMBITI ENERGETICI
Continua='Si';
while strcmp(Continua,'Si')
    Continua='No';
    Rami_da_definire=find(strcmp({Lista_RAMI.Dominio},{' '}));
    for ii_Ramo=Rami_da_definire
        Dominio_Nodo_From=Lista_Nodi(Lista_RAMI(ii_Ramo).From).Dominio;
        Dominio_Nodo_To=Lista_Nodi(Lista_RAMI(ii_Ramo).To).Dominio;
        Nodo_From_is_defined=ismember(Dominio_Nodo_From,'emri');
        Nodo_To_is_defined=ismember(Dominio_Nodo_To,'emri');
        if (Nodo_From_is_defined)&&(Nodo_To_is_defined)
            if Dominio_Nodo_From==Dominio_Nodo_To
                Lista_RAMI(ii_Ramo).Dominio=Dominio_Nodo_From;
                Continua='Si';
            else
                Stringa=['Il ramo ' num2str(ii_Ramo) '-' Lista_RAMI(ii_Ramo).Nome_Ramo ' � collegato ad ambiti energetici ' ...
                    Dominio_Nodo_From ' - ' Dominio_Nodo_To ' diversi!'];
                SHOW_ERRORE(Sistema,Stringa)
            end
        elseif Nodo_From_is_defined
                Lista_RAMI(ii_Ramo).Dominio=Dominio_Nodo_From;
                Lista_Nodi(Lista_RAMI(ii_Ramo).To).Dominio=Dominio_Nodo_From;
                Continua='Si';
        elseif Nodo_To_is_defined
                Lista_RAMI(ii_Ramo).Dominio=Dominio_Nodo_To;
                Lista_Nodi(Lista_RAMI(ii_Ramo).From).Dominio=Dominio_Nodo_To;
                Continua='Si';
        end
    end
end
if not(isempty(Rami_da_definire))
    Sistema.Domini_Omogenei='No';
    disp(' ')
    disp(['Rami_da_definire = ' num2str(Rami_da_definire)])
    disp(['Dominio dei Rami: ' [Lista_RAMI.Dominio]])
    disp(['Dominio dei Nodi: ' [Lista_Nodi.Dominio]])
else
    Sistema.Domini_Omogenei='Si';
end
Schema_ASCII=char(Schema_ASCII);
%%%% I TRASFORMATORI E GIRATORI VENGONO CONVERTITI IN INGRESSI CONTROLLATI
for ii=1:Nr_dei_Rami
    switch Schema_ASCII(ii,1:2)
        case {'bT','bG'}
            if strcmp(Lista_RAMI(ii).Dominio,' ')
                %%% DOMINIO DI DEFAULT: ELETTROMAGNETICO 
                Nome_Ramo='eU';
            else
                Nome_Ramo=[ Lista_RAMI(ii).Dominio 'U'];
            end
            Schema_ASCII(ii,1:2)=Nome_Ramo;
            Lista_RAMI(ii).Nome_Ramo=Nome_Ramo;            
    end
end
Sistema.Schema_ASCII=Schema_ASCII; 
Sistema.Lista_RAMI=Lista_RAMI; 
Sistema.Lista_Nodi=Lista_Nodi;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sistema=CREA_LO_SCHEMA(Sistema)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Schema_ASCII=Sistema.Schema_In;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Schema_ASCII,'Si')
    disp(['Schema Nr.: ' num2str(Sistema.Nr_Schema) ' -> ' Sistema.Title])
    disp(Schema_ASCII)             % Mostra il file ASCII "Schema_In" originario
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Sistema.Show_Schema_In_Senza_Apici,'Si')
    disp(' ')
    for ii=1:length(Schema_ASCII)
        Str=Schema_ASCII{ii};
        Str=strrep(Str,'''','');
        disp(Str)
    end
    disp(' ')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Sistema.Show_ASCII_Latex,'Si')
    disp(' ')
    for ii=1:length(Schema_ASCII)
        Str=Schema_ASCII{ii};
        Str=strrep(Str,'_','\_');
        Str=strrep(Str,'--','-\,-');
        disp([ Str '\\[-1mm]'])
    end
    disp(' ')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% SI FILTRANO ALCUNE PAROLE E ALCUNI COMANDI                        %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii=1:length(Schema_ASCII)
    Str=[strrep(Schema_ASCII{ii},' ','') ','];  % Si tolgono gli spazi
    Str=strrep(Str,',Yes,',',Si,');             % Alcune sostituzioni ...
    Str=strrep(Str,',yes,',',Si,');             % ...
    Str=strrep(Str,',no,',',No,');              % ...
    Ind=strfind(Str,',');                       % Si cercano i separatori
    NewStr=Str(1:Ind(3)-1);                     % Si costruisce una nuova NewStr ...
    for jj=3:2:length(Ind)-2
        Cmd=Str(Ind(jj)+1:Ind(jj+1)-1);         % Viene estratto il comando
        Par=Str(Ind(jj+1)+1:Ind(jj+2)-1);       % Viene estratto il parametro
        AddStr='';
        switch Cmd
            case {'Kn','Qn','En','Fn'}          % Per questi comandi ...
                Nome=Str(1:Ind(1)-1);           % Si estrae il nome del blocco 
                switch Nome
                    case {'CB','BC'}
                    case {'eV','mV','rW','iP'}
                        Pnt=strfind(Par,'=');       % Si cerca la presenza di un '='
                        if not(isempty(Pnt))        % Se '=' � presente ...
                            if strcmp(Cmd,'En')
                                AddStr=[',In0,' Par(Pnt(1)+1:end)];    % Si aggiunge un nuovo comando
                            else
                                disp(['Command "' Cmd '0,' Par(Pnt(1)+1:end) '" NOT USED'])
                            end
                            Par=Par(1:Pnt(1)-1);                        % e si aggiorna il parametro
                        end
                    case {'eI','mF','rT','iQ'}
                        Pnt=strfind(Par,'=');       % Si cerca la presenza di un '='
                        if not(isempty(Pnt))        % Se '=' � presente ...
                            if strcmp(Cmd,'Fn')
                                AddStr=[',In0,' Par(Pnt(1)+1:end)];    % Si aggiunge un nuovo comando
                            else
                                disp(['Command "' Cmd '0,' Par(Pnt(1)+1:end) '" NOT USED'])
                            end
                            Par=Par(1:Pnt(1)-1);                        % e si aggiorna il parametro
                        end
                    otherwise
                        Pnt=strfind(Par,'=');       % Si cerca la presenza di un '='
                        if not(isempty(Pnt))        % Se '=' � presente ...
                            AddStr=[',' Cmd '0,' Par(Pnt(1)+1:end)];    % Si aggiunge un nuovo comando
                            Par=Par(1:Pnt(1)-1);                        % e si aggiorna il parametro
                        end
                end
        end
        NewStr=[NewStr ',' Cmd, ',' Par AddStr];        
    end
    Schema_ASCII{ii}=NewStr;        % La nuova stringa sostituisce quella vecchia
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% SI ESTRAGGONO TUTTE LE RIGHE DI COMANDI CHE INIZIANO CON '**' o '*P' %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Schema_ASCII=char(strrep(Schema_ASCII,' ',''));     % Schema iniziale ASCII
Aux_Schema={};                                      % Variabile ausiliaria
Comandi_ASCII={};                                   % Comandi ASCII
Punti_Schema_ASCII={};                              % Punto dello Schema in ASCII
for ii_Ramo=(1:size(Schema_ASCII,1))
    switch Schema_ASCII(ii_Ramo,1:2)
        case '**'       % La string '**' identifica le righe di comando
            Comandi_ASCII=[Comandi_ASCII; Schema_ASCII(ii_Ramo,:)];
        case '*P'       % La string '*P' identifica i punti dello schema 
            Punti_Schema_ASCII=[Punti_Schema_ASCII; Schema_ASCII(ii_Ramo,:)];
        otherwise       % Tutte le altre stringhe identificano i blocchio del sistema 
            Aux_Schema=[Aux_Schema; Schema_ASCII(ii_Ramo,:)];
    end
end
Comandi_ASCII=char(strrep(Comandi_ASCII,' ',''));               % Lista dei comandi
Punti_Schema_ASCII=char(strrep(Punti_Schema_ASCII,' ',''));     % Punti dello schema
Schema_ASCII_Base=char(strrep(Aux_Schema,' ',''));              % Schema base senza comandi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% CREA LE STRUTTURE PER I PARAMETRI                                 %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Indice_B=Sistema.Indice_B;
Indice_R=Sistema.Indice_R;
Parms_Blocchi=Sistema.Parms_Blocchi;
Parms_Meta_Blocchi=Sistema.Parms_Meta_Blocchi;
Parms_Rami=Sistema.Parms_Rami;
Parms_Sistema=Sistema.Parms_Sistema;
Parametri_Blocchi = COSTRUISCI_LA_STRUTTURA(Parms_Blocchi,Indice_B);
Parametri_Rami = COSTRUISCI_LA_STRUTTURA(Parms_Rami,Indice_R);
Parametri_Sistema = COSTRUISCI_LA_STRUTTURA(Parms_Sistema,Indice_R);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% SOSTITUZIONE_DEI_METABLOCCHI                                      %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sistema.Schema_ASCII_Base=Schema_ASCII_Base;
Sistema.Lista_Nodi_Predefiniti=LEGGI_NODI_PREFEFINITI(Punti_Schema_ASCII);    % Legge la lista dei Nodi predefiniti
Sistema= SOSTITUZIONE_DEI_METABLOCCHI(Sistema);
Schema_ASCII=Sistema.Schema_ASCII;
Lista_RAMI=Sistema.Lista_RAMI;      % Lista dei Rami dello schema filtrato
Lista_Nodi=Sistema.Lista_Nodi;      % Lista dei Nodi dello schema filtrato
if strcmp(Sistema.Show_Schema_ASCII,'Si')
    disp('Schema_ASCII Filtrato:')
    disp(cellstr(Schema_ASCII))
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% SI ANALIZZANO TUTTI I RAMI                                        %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Nr_Blo_emri=0;                             % Numero incrementale dei blocchi di tipo `emri'
Nr_dei_Rami=size(Schema_ASCII,1);           % Ogni riga dello schema definisce un ramo
for ii_Ramo=1:Nr_dei_Rami                   % La virgola ',' separa i parametri 
    Ramo_ii=Lista_RAMI(ii_Ramo);            % Ramo i-esimo
    [Lista_Parametri, Nr_Parametri] = ESTRAI_PARAMETRI(Schema_ASCII(ii_Ramo,:));
    % Il primo parametro identifica il "tipo" di ramo presente fra i punti (From) e (To)
    Nome_Ramo=Lista_Parametri{1}{1}; 	
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                          (E)
    %                     | <--------- | 
    %              (From) * ---------> * (To)
    %                          (F)
    % La variabile E � positiva se ha la punto in (From) e la coda in (To) 
    % La variabile F � positiva se intra in (From) ed esce in (To)
    % Quindi la potenza � ENTRANTE nel ramo che collega (From) a (To) 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% VARIABILI BASE DEL RAMO 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Rami_Input=[];    	% Sequenza di rami orienati che definisce la variabile di ingresso
    Gemello=[];         % Ramo gemello (posizione relativa) con cui � accoppiato il ramo corrente 
    Parallelo_a=[];     % Ramo parallelo (posizione relativa) al ramo corrente 
    TR_o_GY='';         % Trasformatore o giratore 
    Input_POG=[];       % Ramo rispetto al quale sviluppare lo schema POG
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% INIZIALIZZA TUTTE LE VARIABILI DI RAMO CONTENUTI NELLA STRUTTURA "Parametri_Rami"
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for hh=1:length(Parametri_Rami)
        if strcmp(Parametri_Rami(hh).Value,'[]')
            eval([Parametri_Rami(hh).Nome '=' Parametri_Rami(hh).Value ';'])      % I parametri "doppi" sono Vuoti
        else
            Vincoli=Parametri_Rami(hh).Vincoli;
            Range_and_Set=Parametri_Rami(hh).Range_and_Set;
            Nome_Var=Parametri_Rami(hh).Nome;
            Parametro=Parametri_Rami(hh).Value;
            switch Parametri_Rami(hh).StrNum
                case 'Num'
                    Parametro=VERIFICA_NUMERO(Parametro,Vincoli,Range_and_Set,Nome_Var);
                    eval([Nome_Var '=' Parametro ';'])      % Parametri Numerici
                case 'Str'
                    Parametro=VERIFICA_STRINGA(Parametro,Vincoli,Range_and_Set,Nome_Var);
                    eval([Nome_Var '=''' Parametro ''';'])  % Parametri Stringa
                otherwise
                    beep; disp(' '); disp('"NumStr": wrong type of parameter.'); disp(' ')
            end
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% INIZIALIZZA I PARAMETRI DEL BLOCCO PRESENTE ALL'INTERNO DEL RAMO
    %%%% I PARAMETRI SONO QUELLI CONTENUTI NELLA STRUTTURA "Parametri_Blocchi"
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Ind_Blocco=find(strcmp({Parametri_Blocchi.Sigla},Nome_Ramo));    
    if not(isempty(Ind_Blocco))             % Se il Nome_Ramo identifica un Blocco ammissibile ...
        if ismember(Nome_Ramo(1),'emri')
            Nr_Blo_emri=Nr_Blo_emri+1;      % Il numero di "default" viene incrmentato solo per i blocchi 'emri' 
        end
        for Nome_ii=Indice_B
            Nome=Nome_ii{1};
            Parametro=eval(['Parametri_Blocchi(Ind_Blocco).' Nome ';']);    % Valore di Default del Parametro
            switch Nome
                case {'Tipo_di_Ramo', 'Out', 'Diretto', 'E_Str', 'K_Str', 'Q_Str', 'F_Str', 'Show_It'}
                    eval([Nome '=''' Parametro ''';'])
                case {'E_name', 'K_name', 'Q_name', 'F_name'}
                    eval([Nome '=''' Parametro ''';'])
%                     Num=num2str(ii_Ramo);             % Si usa il numero di "ramo"
                    Num=num2str(Nr_Blo_emri);           % Si usa il numero di "default"
                    Numero='';
                    for hh=1:length(Num)
                        Numero=[Numero '_' Num(hh)];
                    end
                    eval([Nome '=[' Nome ' ''' Numero '''];'])
                case 'Comandi'
                    eval(Parametro)
                case {'Sigla', 'Help', 'Help_ENG'}
                    % Nulla 
                otherwise
                    beep; disp(['Errore: parametro di blocco (' Nome ') non previsto!'])
            end
        end
    else
        switch Nome_Ramo
            %%% case Sigla_Ramo
            %%% GESTIONE DI EVENTUALI RAMI PARTICOLARI
            otherwise
                beep; disp('Errore!')
                disp(['Il seguente ELEMENTO FISICO non � definito: ' Nome_Ramo ]); disp(' ')
                Sistema.Analizza_lo_Schema='No';
                Sistema.Grafico.Show_Grafico='No';
                return
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% I COMANDI DI RAMO PRESENTI IN "Schema_ASCII" VENGONO ESEGUITI
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for jj=4:2:Nr_Parametri             % I primi 3 parametri definiscono il Blocco e i due nodi 
        Comando=Lista_Parametri{jj}{1};
        Parametro=Lista_Parametri{jj+1}{1};
        %%% ESECUZIOINE DEI COMANDI CHE DEFINISCONO I PARAMETRI DI RAMO 
        Ind_Ramo=find(strcmp({Parametri_Rami.Sigla},Comando));
        if not(isempty(Ind_Ramo))
            Vincoli=Parametri_Rami(Ind_Ramo).Vincoli;
            Range_and_Set=Parametri_Rami(Ind_Ramo).Range_and_Set;
            Nome_Var=Parametri_Rami(Ind_Ramo).Nome;            
            switch Parametri_Rami(Ind_Ramo).StrNum
                case 'Num'
                    Parametro=VERIFICA_NUMERO(Parametro,Vincoli,Range_and_Set,Nome_Var);
                    eval([Nome_Var '=' Parametro ';'])      % Parametri numerici
                case 'Str'
                    Parametro=VERIFICA_STRINGA(Parametro,Vincoli,Range_and_Set,Nome_Var);
                    eval([Nome_Var '=''' Parametro ''';'])  % Parametri stringa
                otherwise
                    beep; disp(' '); disp('"NumStr": wrong type of parameter.'); disp(' ')
            end
        else
            %%% GESTIONE DEI COMANDI "PARTICOLARI" DI RAMO NON PRESENTI
            %%% ALL'INTERNO DELLA STRUTTURA "Parametri_Rami"
            switch Comando     
                case 'En'                       % Nome della variabile Effort
                    [Parametro, E_up_down]=VERIFICA_LA_POSIZIONE(Parametro, E_up_down);
                    E_name=Parametro;
                case 'Kn'                       % Nome del parametro interno K
                    [Parametro, K_up_down]=VERIFICA_LA_POSIZIONE(Parametro, K_up_down);
                    K_name=Parametro;
                case 'Qn'                       % Nome del parametro interno K
                    [Parametro, Q_up_down]=VERIFICA_LA_POSIZIONE(Parametro, Q_up_down);
                    Q_name=Parametro;
                case 'Fn'                       % Nome della variabile Flow
                    [Parametro, F_up_down]=VERIFICA_LA_POSIZIONE(Parametro, F_up_down);
                    F_name=Parametro;
                case 'II'                       % Ramo parallelo (distanza relativa) al ramo corrente
                    Parallelo_a=eval(Parametro);
                case 'InPOG'                     % Ramo rispetto al quale sviluppare lo schema POG
                    Input_POG=[Input_POG ii_Ramo];
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%%%%% GESTIONE DEI COMANDI RISERVATI %%%%%%%%%%%%%%%%%
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                case 'Ge'                       % Ramo gemello (posizione relativa) al ramo corrente
                    Gemello=eval(Parametro);
                case 'T_G'                      % Trasformatori o Giratori
                    TR_o_GY=Parametro;
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                otherwise
                    beep; disp(' ')
                    disp(['Il seguente parametro di RAMO non � definito: ' Comando ', ' Parametro ])
                    disp(' ')
            end
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% LE VARIABILI En e Kn VENGONO MEMORIZZATE NELLA FORMA SIMBOLICA
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    eval(['syms ' E_name]);    E_name=eval(E_name);
    eval(['syms ' K_name]);    K_name=eval(K_name);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% MEMORIZZAZIONE DI TUTTE LE CARATTERISTICHE DEL RAMO I-ESIMO
    %%%%% TUTTI QUESTI PARAMETRI NON SONO PRESENTI NELLA STRUTTURA Parametri_Rami
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Ramo_ii.Nome_Ramo=Nome_Ramo;        %%% Sigla del ramo
    Ramo_ii.Tipo_di_Ramo=Tipo_di_Ramo;  %%% {'Ingresso', 'Dinamico', 'Resitivo', 'Filo'}
    Ramo_ii.SP='Foglia';                %%% {'Foglia', 'Serie', 'Parallelo'}. Tipo di ramo
    Ramo_ii.SP_Out={};                  %%% {'Effort',  'Flow'}. Orientamento dei rami 
    Ramo_ii.Rami_Input=Rami_Input;      %%% Indice del nodo che fornisce il Flow o l'Effort
    Ramo_ii.Gemello=Gemello;            %%% Ramo gemello (posizione relativa) con cui � accoppiato il ramo corrente
    Ramo_ii.Parallelo_a=Parallelo_a;	%%% Ramo parallelo al ramo corrente
    Ramo_ii.TR_o_GY=TR_o_GY;            %%% Trasformatore o giratore
    Ramo_ii.E_name=E_name;              %%% Nome che si vuol utilizzare per la variabile Effort
    Ramo_ii.K_name=K_name;              %%% Nome che si vuol utilizzare per il parametro 'energia'
    Ramo_ii.Q_name=Q_name;              %%% Nome che si vuol utilizzare per della variabile 'energia'
    Ramo_ii.F_name=F_name;              %%% Nome che si vuol utilizzare per la variabile di Flow
    Ramo_ii.E_Str=E_Str;                %%% Stringa che definisce il significato della variabile Effort
    Ramo_ii.K_Str=K_Str;                %%% Stringa che definisce il significato del parametro 'energia'
    Ramo_ii.Q_Str=Q_Str;                %%% Stringa che definisce il significato della variabile 'energia'
    Ramo_ii.F_Str=F_Str;                %%% Stringa che definisce il significato della variabile Flow
    Ramo_ii.From_Plot=Ramo_ii.From;     %%% Numero interno del nodo di partenza da usare nel Plot
    Ramo_ii.To_Plot=Ramo_ii.To;         %%% Numero interno del nodo di arrivo da usare nel Plot
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% LE VARIABILI DI RAMO VENGONO MEMORIZZAZIONE NELLE STRUTTURE "Plot", "Ramo_ii" e "POG"
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for hh=1:length(Parametri_Rami)
        if strcmp(Parametri_Rami(hh).Type,'Plot')
            eval(['Plot.' Parametri_Rami(hh).Nome '=' Parametri_Rami(hh).Nome ';'])
        elseif strcmp(Parametri_Rami(hh).Type,'Ramo')
            eval(['Ramo_ii.' Parametri_Rami(hh).Nome '=' Parametri_Rami(hh).Nome ';'])
        elseif strcmp(Parametri_Rami(hh).Type,'POG')
            eval(['POG.' Parametri_Rami(hh).Nome '=' Parametri_Rami(hh).Nome ';'])
        else
            beep; disp(' ')
            disp(['La tipologia di paramatro NON  � definita: ' Parametri_Rami(hh).Type ])
            disp(' ')
        end
    end
    Ramo_ii.Plot=Plot;
    Ramo_ii.POG=POG;
    Lista_Rami(ii_Ramo)=Ramo_ii;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% INIZIALIZZA LE VARIABILI DI SISTEMA 
%%%% (ANCHE QUELLE CONTENUTE NELLA STRUTTURA "Parametri_Rami")
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for hh=1:length(Parametri_Sistema)
    Vincoli=Parametri_Sistema(hh).Vincoli;
    Range_and_Set=Parametri_Sistema(hh).Range_and_Set;
    Parametro=Parametri_Sistema(hh).Value;
    Nome_Var=Parametri_Sistema(hh).Nome;
    switch Parametri_Sistema(hh).StrNum
        case 'Num'
            Parametro=VERIFICA_NUMERO(Parametro,Vincoli,Range_and_Set,Nome_Var);
            eval([Nome_Var '=' Parametro ';'])      % Parametri numerici
        case 'Str'
            Parametro=VERIFICA_STRINGA(Parametro,Vincoli,Range_and_Set,Nome_Var);
            eval([Nome_Var '=''' Parametro ''';'])  % Parametri stringa
        otherwise
            beep; disp(' '); disp('"NumStr": wrong type of parameter.'); disp(' ')
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Rimpiazza={};               % Indica il valore da assegnare ad una variabile
Schema_Analizzato='No';     % Indica se lo schema � stato analizzato o no
Schema_POG_Generato='No';  % Indica se lo schema POG � stato generato o no
Schema_SLX_Generato='No';  % Indica se lo schema Simulink � stato generato o no
Rami_Orientati='No';        % Indica se i rami dello schema sono stati orientati o no
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ESECUZIONE DEI COMANDI DI SISTEMA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
Nr_delle_righe_comando=size(Comandi_ASCII,1);
for ii_Ramo=1:Nr_delle_righe_comando
    [Lista_Parametri, Nr_Parametri] = ESTRAI_PARAMETRI(Comandi_ASCII(ii_Ramo,:));
    if mod(Nr_Parametri,2)==0
        beep
        disp(['The following string is surely wrong: "' Comandi_ASCII(ii_Ramo,:) '"'])
    else
        for jj=2:2:Nr_Parametri
            Comando=Lista_Parametri{jj}{1};
            Parametro=Lista_Parametri{jj+1}{1};
            %%%% GESTIONE DEI COMANDI BASE DI SISTEMA
            Ind_Sistema=find(strcmp({Parametri_Sistema.Sigla},Comando));
            if not(isempty(Ind_Sistema))
                Vincoli=Parametri_Sistema(Ind_Sistema).Vincoli;
                Range_and_Set=Parametri_Sistema(Ind_Sistema).Range_and_Set;
                Nome_Var=Parametri_Sistema(Ind_Sistema).Nome;
                switch Parametri_Sistema(Ind_Sistema).StrNum
                    case 'Num'
                        Parametro=VERIFICA_NUMERO(Parametro,Vincoli,Range_and_Set,Nome_Var);
                        eval([Nome_Var '=' Parametro ';'])      % Parametri numerici
                    case 'Str'
                        Parametro=VERIFICA_STRINGA(Parametro,Vincoli,Range_and_Set,Nome_Var);
                        eval([Nome_Var '=''' Parametro ''';'])  % Parametri stringa
                    otherwise
                        beep; disp(' '); disp('Tipo "NumStr" sbagliato di parametro.'); disp(' ')
                end
            else
                %%%% GESTIONE DEI COMANDI "PARTICOLARI" DI SISTEMA
                switch Comando
                    case 'Rp'                       % Indica il valore da assegnare ad una variabile
                        [Par1,Par2] = SEPARA(Parametro,'=');
                        Rimpiazza(size(Rimpiazza,1)+1,:)={Par1,Par2};
                    case 'Help'                     % Help sui "B"locchi, "MB"locchi, "R"ami e "S"istema
                        if not(strcmp(Parametro,'No'))
                            Tutti = {...
                                {'Parms_Rami',        'Indice_R','Comandi Specifici di ciascun Ramo ','R'},...
                                {'Parms_Blocchi',     'Indice_B','Lista dei Blocchi','B'},...
                                {'Parms_Meta_Blocchi','Indice_B','Lista dei Meta-Blocchi','B'},...
                                {'Parms_Sistema',     'Indice_R','Lista dei comandi di Sistema','S'},...
                                };
                            fh=fopen('Help_POG.m','w');
                            mywrite(fh,'echo on');
                            for ii=1:length(Tutti)
                                Lista=CREA_HELP(eval(Tutti{ii}{1}),eval(Tutti{ii}{2}),Tutti{ii}{3},Tutti{ii}{4},Parametro,Help_in_English);
                                Nr_Righe=length(Lista);
                                for rr=1:Nr_Righe
                                    mywrite(fh,['% ' Lista{rr}]);
                                end
                            end
                            mywrite(fh,'echo off');
                            fclose(fh);
                        end
                    otherwise
                        beep; disp(' ')
                        disp(['Il seguente parametro di SISTEMA non � definito: ' Comando ', ' Parametro ])
                        disp(' ')
                end
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%  VISUALIZZA I PARAMETRI CHE VERRANNO RIMPIAZZATI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if size(Rimpiazza,1)>0
    disp('Parametri rimpiazzati:');   disp(Rimpiazza)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% I PARAMETRI DI SYSTEMA VENGONO MEMORIZZATI NELLA STRUTTURE "Grafico" e "POG"  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for hh=1:length(Parametri_Sistema)
    if strcmp(Parametri_Sistema(hh).Type,'Grafico')
        eval(['Grafico.' Parametri_Sistema(hh).Nome '=' Parametri_Sistema(hh).Nome ';'])
    elseif strcmp(Parametri_Sistema(hh).Type,'POG')
        eval(['POG_SYS.' Parametri_Sistema(hh).Nome '=' Parametri_Sistema(hh).Nome ';'])
    elseif strcmp(Parametri_Sistema(hh).Type,'Sistema')
        % Nulla 
    else
        beep; disp(' ')
        disp(['La tipologia di paramatro NON  � definita: ' Parametri_Sistema(hh).Type ])
        disp(' ')
    end
end
if strcmp(Grafico.Nome_del_grafico,'__')
    Grafico.Nome_del_grafico=IS_A_FILE_NAME(Sistema.Title,'Nome_del_grafico'); 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% I PARAMETRI DI RAMO NON DEFINITI EREDITANO IL VALORE DI SISTEMA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii_Ramo=1:Nr_dei_Rami
    for hh=1:length(Parametri_Rami)
        Doppio=Parametri_Rami(hh).Nome;
        if strcmp(Parametri_Rami(hh).Type,'Plot')
            eval(['Val=Lista_Rami(' num2str(ii_Ramo) ').Plot.' Doppio ';'])
            if isempty(Val)
                eval(['Lista_Rami(' num2str(ii_Ramo) ').Plot.' Doppio '=Grafico.' Doppio ';'])
            end
        elseif strcmp(Parametri_Rami(hh).Type,'POG')
            eval(['Val=Lista_Rami(' num2str(ii_Ramo) ').POG.' Doppio ';'])
            if isempty(Val)
                eval(['Lista_Rami(' num2str(ii_Ramo) ').POG.' Doppio '=POG_SYS.' Doppio ';'])
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CALCOLO DELLA POSIZIONE DEI NODI 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii=1:Nr_dei_Rami
    From_Plot=Lista_Rami(ii).From_Plot;
    To_Plot=Lista_Rami(ii).To_Plot;
    From_is_not_defined=Lista_Nodi(From_Plot).Posizione==Inf;
    To_is_not_defined=Lista_Nodi(To_Plot).Posizione==Inf;
    if (From_is_not_defined)&&(To_is_not_defined)
        if ii==1
            P0=Point_P0;
            Lista_Nodi(From_Plot).Posizione=P0;
        else
            [~,~,X1,Y1]=CALCOLA_ESTREMI([Lista_Nodi.Posizione]);
            P0=X1+0.7+1i*Y1;
            Lista_Nodi(From_Plot).Posizione=P0;
            if not(isempty(Lista_Rami(ii).Parallelo_a))
                Ramo_II=ii+Lista_Rami(ii).Parallelo_a;
                From_II=Lista_Rami(Ramo_II).From_Plot;
                To_II=Lista_Rami(Ramo_II).To_Plot;
                From_II_Pos=Lista_Nodi(From_II).Posizione;
                To_II_Pos=Lista_Nodi(To_II).Posizione;
                if (From_II_Pos~=Inf)&&(To_II_Pos~=Inf)
                    Shift=-(From_II_Pos-To_II_Pos)*1i;
                    Lung=Lista_Rami(ii).Plot.Lateral+Lista_Rami(Ramo_II).Plot.Shift-Lista_Rami(ii).Plot.Shift;
                    Lista_Nodi(From_Plot).Posizione=From_II_Pos+Lung*Shift/abs(Shift);
                    Lista_Nodi(To_Plot).Posizione=To_II_Pos+Lung*Shift/abs(Shift);
                    To_is_not_defined=false;
                    From_is_not_defined=false;                    
                end
            end
        end
    end
    if To_is_not_defined
        Lista_Nodi(To_Plot).Posizione=Lista_Nodi(From_Plot).Posizione+Lista_Rami(ii).Plot.Lung*exp(1i*pi*Lista_Rami(ii).Plot.Angle/180);
    elseif From_is_not_defined
        Lista_Nodi(From_Plot).Posizione=Lista_Nodi(To_Plot).Posizione-Lista_Rami(ii).Plot.Lung*exp(1i*pi*Lista_Rami(ii).Plot.Angle/180);        
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% NUOVO ORDINAMENTO DEL RAMI DELLO SCHEMA 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Pnt_CC=[];
Pnt_Utili=[];
Pnt_Filo=[];
for ii=1:Nr_dei_Rami
    if ismember(Lista_Rami(ii).Nome_Ramo(1),'emri')
        Pnt_Utili=[Pnt_Utili ii];                   % Prima tutti i blocchi utili
    elseif strcmp(Lista_Rami(ii).Nome_Ramo,'--')
        Pnt_CC=[Pnt_CC ii];                         % ... poi i rami corto-circuito "--"
    else
        Pnt_Filo=[Pnt_Filo ii];                     % ... e alla fine gli altri blocchi "Filo"
    end
end
Nuovo_Ordine_Rami=[Pnt_Utili Pnt_CC Pnt_Filo];
Lista_Rami=Lista_Rami(Nuovo_Ordine_Rami);	% Riordinamento della struttura "Lista_Rami"
for jj=1:length(Input_POG)                  % Nuovo ordinamento di "Input_POG"
    Input_POG(jj)=find(Input_POG(jj)==Nuovo_Ordine_Rami);
end
Nr_Rami_Utili=length(Pnt_Utili);
Nr_Rami_CC=length(Pnt_CC);
Nr_Rami_Filo=length(Pnt_Filo);
Rami_Utili=1:Nr_Rami_Utili;
Rami_CC=Nr_Rami_Utili+(1:Nr_Rami_CC);
Rami_Filo=Nr_Rami_Utili+Nr_Rami_CC+(1:Nr_Rami_Filo);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% SI TOLGONO I CORTO CIRCUITI '--' DALLO SCHEMA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Nr_dei_Nodi=length(Lista_Nodi);
Nodi_Utili=1:Nr_dei_Nodi;
for ii_Ramo=Rami_CC
    Tieni_Nodo=Lista_Rami(ii_Ramo).From;
    Butta_Nodo=Lista_Rami(ii_Ramo).To;
    Nodi_Utili=setdiff(Nodi_Utili,Butta_Nodo);
    for jj=1:Nr_dei_Rami
        if jj==ii_Ramo
            Lista_Rami(jj).To=Tieni_Nodo;
            Lista_Nodi(Butta_Nodo).Nome=Tieni_Nodo;
        else
            if Lista_Rami(jj).From==Butta_Nodo
                Lista_Rami(jj).From=Tieni_Nodo;
            end
            if Lista_Rami(jj).To==Butta_Nodo
                Lista_Rami(jj).To=Tieni_Nodo;
            end
        end
    end
end
Nr_Nodi_Utili=length(Nodi_Utili);
Nodi_CC=setdiff(1:Nr_dei_Nodi,Nodi_Utili);
Nr_Nodi_CC=length(Nodi_CC);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% NUOVO ORDINAMENTO DEI NODI DELLO SCHEMA 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Nuovo_Ordine_Nodi=[Nodi_Utili Nodi_CC];
for jj=1:Nr_dei_Rami    % Nuovo ordinamento dei nomi dei Nodi all'interno dei Rami
    Lista_Rami(jj).From=find(Lista_Rami(jj).From==Nuovo_Ordine_Nodi);
    Lista_Rami(jj).To=find(Lista_Rami(jj).To==Nuovo_Ordine_Nodi);
    %%%%
    Lista_Rami(jj).From_Plot=find(Lista_Rami(jj).From_Plot==Nuovo_Ordine_Nodi);
    Lista_Rami(jj).To_Plot=find(Lista_Rami(jj).To_Plot==Nuovo_Ordine_Nodi);
end
for jj=1:Nr_dei_Nodi    % Nuovo ordinamento dei nomi dei Nodi
    Lista_Nodi(jj).Nome=find(Lista_Nodi(jj).Nome==Nuovo_Ordine_Nodi);
end
Lista_Nodi=Lista_Nodi(Nuovo_Ordine_Nodi);   % Nuovo ordinamento della Lista_Nodi
Nodi_Utili=1:Nr_Nodi_Utili;
Nodi_CC=Nr_Nodi_Utili+(1:Nr_Nodi_CC);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% disp( [Rami_Utili;  Lista_Rami(Rami_Utili).From; Lista_Rami(Rami_Utili).To])
%  disp( [1:Nr_dei_Rami;  Lista_Rami.From; Lista_Rami.To])
%  disp(1:Nr_dei_Nodi)
%  disp({Lista_Nodi.Dominio})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% CREA LA "Lista_Nodi" = INDICA I RAMI CHE PARTONO DAL NODO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Show_Details,'Si'); 
    disp('%%%%%%%% Variabile: "Lista_Nodi"'); 
end                              %%%% SHOW SHOW SHOW
for ii=Nodi_Utili                    % Rami che partono da ciascun nodo
    Lista_Nodi(ii).Nome=ii;
    Rami_From=Rami_Utili([Lista_Rami(Rami_Utili).From]==ii);
    Rami_To=Rami_Utili([Lista_Rami(Rami_Utili).To]==ii);
    Lista_Nodi(ii).Next_Rami=[Rami_From -Rami_To];
    Lista_Nodi(ii).Next_Nodi=[Lista_Rami(Rami_From).To Lista_Rami(Rami_To).From];
    [Lista_Nodi(ii).Next_Nodi,Ind]=sort(Lista_Nodi(ii).Next_Nodi);
    Lista_Nodi(ii).Next_Rami=Lista_Nodi(ii).Next_Rami(Ind);
    if strcmp(Show_Details,'Si'); disp([ii Inf Lista_Nodi(ii).Next_Rami]); end                              %%%% SHOW SHOW SHOW
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% CALCOLO DELLE PARTIZIONI DELLO SCHEMA  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Nodi_da_ridurre=Nodi_Utili;     ii=0;   
while not(isempty(Nodi_da_ridurre))
    ii=ii+1;
    Partizione(ii).Rami=[];
    Partizione(ii).Nodi=[];
    Partizione(ii) = CALCOLA_LA_PARTIZIONE_NODI_E_RAMI(Lista_Nodi,Partizione(ii),Nodi_da_ridurre(1));
    Nodi_da_ridurre=setdiff(Nodi_da_ridurre,Partizione(ii).Nodi);
    if isempty(Partizione(ii).Rami)
        ii=ii-1;                    % Partizione senza rami
    end
end
Partizione=Partizione(1:ii);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% CALCOLO DELLA SEQUENZA OTTIMALE DELLE PARTIZIONI  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(Input_POG);    Input_POG=1;   end
Coda_Rami=Input_POG(1);         kk=1;   
Old_Elenco=1:length(Partizione);   
New_Elenco=[];   
while not(isempty(Old_Elenco))
    if isempty(Coda_Rami)
        if length(Input_POG)>kk
            kk=kk+1;
            Coda_Rami=Input_POG(kk);
        else
            Coda_Rami=Partizione(Old_Elenco(1)).Rami(1);
            kk=kk+1;
            Input_POG(kk)=Coda_Rami;
        end
    end
    Ramo=Coda_Rami(1);
    Ind=NR_PARTIZIONE_CHE_CONTIENE_IL_RAMO(Partizione,Ramo);
    Partizione(Ind).Ramo_UNO=Ramo;
    Coda_Rami=Coda_Rami(2:end);
    Old_Elenco=setdiff(Old_Elenco,Ind);
    New_Elenco=[New_Elenco Ind];
    %%%% RICERCA DEI BLOCCHI "CONNESSIONE"
    Next_Rami=Partizione(Ind).Rami; hh=0; clear Links 
    Links=[];
    for jj=1:length(Next_Rami)
        Ramo_jj=Next_Rami(jj);
        if abs(Lista_Rami(Ramo_jj).Gemello)==1
            hh=hh+1;
            Links(hh).Primo=Ramo_jj;            
            Links(hh).Secondo=Ramo_jj+Lista_Rami(Ramo_jj).Gemello;
            Links(hh).Forward='No';
            Ramo=Links(hh).Secondo;
            Ind_2=NR_PARTIZIONE_CHE_CONTIENE_IL_RAMO(Partizione,Ramo);
            Links(hh).Next_Partiz=Ind_2;
            if ismember(Ind_2,setdiff(Old_Elenco,[Links(1:hh-1).Next_Partiz]))
                Links(hh).Forward='Si'; 
                Coda_Rami=[Coda_Rami Links(hh).Secondo];
            end
        end
    end
    Partizione(Ind).Links=Links;
end
%%%% NUOVO ORDINAMENTO DELLE PARTIZIONI  
Partizione=Partizione(New_Elenco);
for ii=1:length(Partizione)
    for jj=1:length(Partizione(ii).Links)
        Partizione(ii).Links(jj).Next_Partiz=find(New_Elenco==Partizione(ii).Links(jj).Next_Partiz);
    end
end
Sistema.Partizione=Partizione;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% PARAMETRI DI SCHEMA "NON" DEFINIBILI DALL'UTENTE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sistema.Comandi_ASCII=Comandi_ASCII;
Sistema.Schema_ASCII =Schema_ASCII;
Sistema.Nr_dei_Rami=Nr_dei_Rami;
Sistema.Nr_dei_Nodi=Nr_dei_Nodi;
Sistema.Lista_Rami=Lista_Rami;
Sistema.Lista_Nodi=Lista_Nodi;
Sistema.Grafico=Grafico;
Sistema.POG_SYS=POG_SYS;
Sistema.Nr_Rami_Utili=Nr_Rami_Utili;
Sistema.Nr_Rami_CC=Nr_Rami_CC;
Sistema.Nr_Rami_Filo=Nr_Rami_Filo;
Sistema.Rami_Utili=Rami_Utili;
Sistema.Rami_CC=Rami_CC;
Sistema.Rami_Filo=Rami_Filo;
Sistema.Nr_Nodi_Utili=Nr_Nodi_Utili;
Sistema.Nodi_Utili=Nodi_Utili;
Sistema.Nr_Nodi_CC=Nr_Nodi_CC;
Sistema.Nodi_CC=Nodi_CC;
Sistema.Schema_Analizzato=Schema_Analizzato;            % Non modificabile dall'esterno
Sistema.Schema_POG_Generato=Schema_POG_Generato;        % Non modificabile dall'esterno
Sistema.Schema_SLX_Generato=Schema_SLX_Generato;        % Non modificabile dall'esterno
Sistema.Rami_Orientati=Rami_Orientati;                  % Non modificabile dall'esterno
Sistema.Rimpiazza=Rimpiazza;
Sistema.Input_POG=Input_POG;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% I PARAMETRI DI SISTEMA VENGONO MEMORIZZATI IN "SISTEMA" 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for hh=1:length(Parametri_Sistema)
    if strcmp(Parametri_Sistema(hh).Type,'Sistema')
        eval(['Sistema.' Parametri_Sistema(hh).Nome '=' Parametri_Sistema(hh).Nome ';'])
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% PARAMETRI: NOMI, VALORI E SIGNIFICATO    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[Par_Val, Par_Str, Par_Typ] = GET_PARAMETERS_VALUES(Sistema);
Nomi=fieldnames(Par_Val);
%%%% Calcolo della massima lunghezza dei parametri
Max_Length=0;               
for ii=1:length(Nomi)
    Line=[Nomi{ii} '=' num2str(getfield(Par_Val,Nomi{ii})) ';'];
    if length(Line)>Max_Length
        Max_Length=length(Line);
    end
end
Max_Length=Max_Length+5;                    % Punto di inizio commenti
for ii=1:length(Nomi)
    Parametri(ii).Nome = Nomi{ii};
    Parametri(ii).Value = getfield(Par_Val,Nomi{ii});
    Parametri(ii).Type = getfield(Par_Typ,Nomi{ii});
    Parametri(ii).Meaning = getfield(Par_Str,Nomi{ii});
    Line=[Nomi{ii} '=' num2str(getfield(Par_Val,Nomi{ii})) ';'];
    Parametri(ii).Line=[Line blanks(Max_Length-length(Line)) '% ' getfield(Par_Str,Nomi{ii})];
end
Sistema.Parametri=Parametri;
%.....
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Nodi_Predefiniti=LEGGI_NODI_PREFEFINITI(Punti)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
kk=1;
Nodi_Predefiniti(kk).Nome=' ';
Nodi_Predefiniti(kk).Posizione=0;
Nr_di_righe=size(Punti,1);
for ii_Riga=1:Nr_di_righe
    [Lista_Parametri, Nr_Parametri] = ESTRAI_PARAMETRI(Punti(ii_Riga,:));
    for jj=2:Nr_Parametri
        Parametro=Lista_Parametri{jj}{1};
        [Par1,Par2] = SEPARA(Parametro,'=');
        if not(isempty(Par2))
            if not(ismember(Par1,[Nodi_Predefiniti.Nome]))
                Nodi_Predefiniti(kk).Nome=Par1;
                Nodi_Predefiniti(kk).Posizione=Par2;
                kk=kk+1;
            end
        else
            beep; disp(' ')
            disp(['Il seguente Punto non � stato definito: ' Parametro ])
            disp(' ')
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

                    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Numero=VERIFICA_NUMERO(Numero,Vincoli,Range_and_Set,Nome_Var)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Numero=str2num(Numero);
if not(isempty(Range_and_Set))
    Range_and_Set=eval(Range_and_Set);
end
switch Vincoli
    case 'Free'
    case 'Real'
        Numero=LIMITA(Numero,Range_and_Set,Nome_Var);
    case 'Int'
        Numero=LIMITA(round(Numero),round(Range_and_Set),Nome_Var);
    case 'Set'
        Numero=NUMBER_BELONG_TO_SET(Numero,Range_and_Set,Nome_Var);
    otherwise
end
if length(Numero)==1
    Numero=num2str(Numero);
else
    Numero=['[' num2str(Numero) ']'];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Stringa=VERIFICA_STRINGA(Stringa,Vincoli,Range_and_Set,Nome_Var)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch Vincoli
    case 'Free'
    case 'Name'
        Stringa=IS_A_FILE_NAME(Stringa,Nome_Var);
    case 'Set'
        Stringa=STRING_BELONG_TO_SET(Stringa,Range_and_Set,Nome_Var);
    otherwise
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Numero=LIMITA(Numero,Range_and_Set,Nome_Var)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if Numero<Range_and_Set(1)
    beep; disp(' '); disp(['Variabile "' Nome_Var '": il numero "' Numero '" -> "' Range_and_Set(1) '" � stato saturato verso il basso']); disp(' ')
    Numero=Range_and_Set(1);
elseif Numero>Range_and_Set(end)
    beep; disp(' '); disp(['Variabile "' Nome_Var '": il numero "' Numero '" -> "' Range_and_Set(end) '" � stato saturato verso il l''alto']); disp(' ')
    Numero=Range_and_Set(end);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Numero=NUMBER_BELONG_TO_SET(Numero,Set,Nome_Var)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(intersect(Numero,Set))
    beep; disp(' '); disp(['Variabile "' Nome_Var '": il numero "' num2str(Numero) '" -> "' num2str(Set(1)) '" � stato posto uguale al primo valore disponibile']); disp(' ')
    Numero=Set(1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Numero=STRING_BELONG_TO_SET(Numero,Set,Nome_Var)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(intersect(Numero,Set))
    beep; disp(' '); disp(['Variabile "' Nome_Var '": la stringa "' Numero '" -> "' Set{1} '" � stata posta uguale al primo valore disponibile']); disp(' ')
    Numero=Set{1};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Stringa=IS_A_FILE_NAME(Stringa_In,Nome_Var)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Stringa=strrep(Stringa_In,' ','_');
New_Str='';
ii=1;
while (isempty(New_Str)&&(ii<=length(Stringa)))
    if ismember(Stringa(ii),'abcdefghkijlmnopqrstuvzxywABCDEFGHKIJLMNOPQRSTUVZXYW_')
        New_Str=Stringa(ii);
    end
    ii=ii+1;
end
for jj=ii:length(Stringa)
    if ismember(Stringa(jj),'abcdefghkijlmnopqrstuvzxywABCDEFGHKIJLMNOPQRSTUVZXYW_.1234567890')
        New_Str=[New_Str Stringa(jj)];
    end
end
if isempty(New_Str)
    New_Str='Grafico';
end
if not(strcmp(Stringa,New_Str))
    beep; disp(' '); disp(['Variabile "' Nome_Var '": la stringa "' Stringa '" -> "' New_Str '" � stata posta uguale al primo valore disponibile']); disp(' ')
    Stringa=New_Str;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Ind=NR_PARTIZIONE_CHE_CONTIENE_IL_RAMO(Partizione,Ramo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ind=1;
while not(ismember(Ramo,Partizione(Ind).Rami))
    Ind=Ind+1;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Partizione=CALCOLA_LA_PARTIZIONE_NODI_E_RAMI(Lista_Nodi,Partizione,Nodo_Start)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Next_Nodi=Lista_Nodi(Nodo_Start).Next_Nodi;
    Next_Rami=Lista_Nodi(Nodo_Start).Next_Rami;
    Partizione.Rami=unique([Partizione.Rami abs(Next_Rami)]);
    New_Nodi=setdiff(Next_Nodi,Partizione.Nodi);    
    Partizione.Nodi=unique([Partizione.Nodi Nodo_Start Next_Nodi]);
    for New_Nodo_ii=New_Nodi
        Partizione=CALCOLA_LA_PARTIZIONE_NODI_E_RAMI(Lista_Nodi,Partizione,New_Nodo_ii);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Lista=CREA_HELP(Parms,Indice,String,Tipo,Parametro,Help_in_English)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Nr_Parms=length(Parms);
Lista{1}={};
Lista{Nr_Parms+2}={};
Lista{1}=' ';
Lista{2}=['****  ' upper(String)];
if strcmp(Help_in_English,'Si')
    Help_ii= strcmp(Indice,'Help_ENG');
else
    Help_ii= strcmp(Indice,'Help');
end
Sigla_ii= strcmp(Indice,'Sigla');
Value_ii= find(strcmp(Indice,'Value'));
for ii=1:Nr_Parms
    Prima_Parte=[Parms{ii}{Sigla_ii} '       '];
    Seconda_Parte='';
    if not(isempty(Value_ii))
        Seconda_Parte=[Parms{ii}{Value_ii} '        '];
        Seconda_Parte=Seconda_Parte(1:7);
    end
    Stringa=[Prima_Parte(1:4) ' ' Seconda_Parte  ' ' Parms{ii}{Help_ii} ];
    Lista{ii+2}=Stringa;
    if strcmp(Parms{ii}{Sigla_ii},Parametro)
        disp(Lista{1})
        disp(Lista{2})
        disp(Stringa)
    end
end
if strcmp(Tipo,Parametro)||strcmp(Parametro,'Si')
    for ii=1:length(Lista)
        disp(Lista{ii})
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  STAMPA_CSV(Parms,Indice,File)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Separa=';';                             % Separatore tra i parametri nel file .CVS
Separa_Set=',';                         % Separatore all'interno di un parametro nel file .CVS
Ind_Show_It=find(strcmp(Indice,'Show_It'));
fh=fopen([File '.CSV'],'w');
for hh=0:length(Parms)
    OK=false;
    if (hh==0)||strcmp(Parms{hh}{Ind_Show_It},'Si')
        OK=true;
    end
    if OK   % Vengono copiati solo i parametri Show_It='Si'
        Line='';
        for kk=[1:Ind_Show_It-1 Ind_Show_It+1:length(Indice)] % La colonna "Show_It" non viene copiata 
            if hh==0
                Parametro=Indice{kk};       % La prima riga (hh=0) contiene le parole Indice
            else
                Parametro=Parms{hh}{kk};    % tutte le altre righe ciontengono i parametri
            end
            if isstr(Parametro)                                 % Se il parametro � una stringa
                Parametro=strrep(Parametro,'''',' ');           % ... si tolgono gli accenti
                Parametro=strrep(Parametro,';',Separa_Set);     % ... il separatore ';' � sostituito con ','
            end
            switch Indice{kk}
                case {'Range_and_Set'}
                    if hh==0
                        Par=Parametro;
                    else
                        Par='';
                        if iscell(Parametro)
                            Par2=Parametro;
                        else
                            if not(isempty(Parametro))
                                Par2=eval(Parametro);
                            else
                                Par2='';
                            end
                        end
                        if isnumeric(Par2)
                            for ii=1:length(Par2)
                                Par=[Par num2str(Par2(ii)) Separa_Set];
                            end
                        else
                            for ii=1:length(Par2)
                                Par=[Par Par2{ii} Separa_Set];
                            end
                        end
                    end
                    if not(isempty(Par))
                        if hh>0
                            Par=Par(1:end-1);
                        end
                    end
                    Line=[Line Par Separa];
                otherwise
                    Line=[Line Parametro Separa];
            end
        end
        Line=Line(1:end-1);
        disp(Line)
        mywrite(fh,Line);
    end
end
fclose(fh);
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Parametri_Sistema = COSTRUISCI_LA_STRUTTURA(Parms,Indice)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for hh=1:length(Parms)
    for kk=1:length(Indice)
        % Gli apici nelle stringhe vanno raddoppiati 
        Parametro=Parms{hh}{kk};
        if isstr(Parametro)     % Il parametro � una stringa
            Stringa=strrep(Parametro,'''','''''');
            eval(['Parametri_Sistema(' num2str(hh) ').' Indice{kk} '=''' Stringa ''';'])
        else                    % Il parametro � una struttura
            Stringa=Parametro;
            eval(['Parametri_Sistema(' num2str(hh) ').' Indice{kk} '=Stringa;'])
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [Parametro, E_up_down] = VERIFICA_LA_POSIZIONE(Parametro, E_up_down)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if Parametro(1)=='-'
        Parametro=Parametro(2:end);  E_up_down=-E_up_down;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [Parametri, Nr_Parametri] = ESTRAI_PARAMETRI(Riga)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ind=[strfind(Riga,',') length(deblank(Riga))+1];
Nr_Parametri=length(Ind);
Ind=[0 Ind];
for jj=1:Nr_Parametri
    Nome_Vero=Riga(Ind(jj)+1:Ind(jj+1)-1);          % Nome esterno del nodo
    % I nodi dei blocchi di connessione (Tr e Gy) sono doppi: "[a;b]"
    Nome_Vero=strrep(Nome_Vero,'[','');             % Toglie "["
    Nome_Vero=strrep(Nome_Vero,']','');             % Toglie "]"
    Nome_Vero=strrep(Nome_Vero,';',''';''');        % Sostituzione:  ; -> ';'
    Nome_Vero=eval(['{''' Nome_Vero '''}']);        % a -> {'a'}; [a;b] -> {'a';'b'};      
    Parametri(jj)={Nome_Vero};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function   SHOW_ERRORE(Sistema,Stringa)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
beep; disp('Errore!'); disp(Stringa)
if not(isfield(Sistema,'Show_Details'))
    Sistema.Show_Details='No';
end
if strcmp(Sistema.Show_Details,'Si')
    for ii=(1:Sistema.Nr_dei_Rami)
        disp(['Ramo ' num2str(ii) ' :']);  disp(Sistema.Lista_Rami(ii))
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%...%%%%%%%%%%   EQUAZIONI_NELLO_SPAZIO_DEGLI_STATI    %%%%%%%%%%%%%%%%%%%%
%...%%%%%%%%%%   EQUAZIONI_NELLO_SPAZIO_DEGLI_STATI    %%%%%%%%%%%%%%%%%%%%
%...%%%%%%%%%%   EQUAZIONI_NELLO_SPAZIO_DEGLI_STATI    %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sistema=EQUAZIONI_NELLO_SPAZIO_DEGLI_STATI(Sistema)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global Lista_Rami Lista_Nodi Verifica_Old
%%%%
Lista_Rami=Sistema.Lista_Rami;
Lista_Nodi=Sistema.Lista_Nodi;     
Show_Details=Sistema.Show_Details;      % Indica se mostrare i dettagli di alcune variabili
Verifica_Old=Sistema.Verifica_Old;      % Verifica la compatibilita' con la vecchia versione
%%%%
Nr_dei_Rami=Sistema.Nr_dei_Rami;     	% Numero dei rami dello schema
Rami_Utili=Sistema.Rami_Utili;
Nodi_Utili=Sistema.Nodi_Utili;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%% SE RICHIESTO VISUALIZZA I RAMI
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if strcmp(Show_Details,'Si')
%     for ii=(1:Nr_dei_Rami);  disp(['Ramo nr. ' num2str(ii)]); SHOW_RAMO(Lista_Rami(ii)); end     %%%% SHOW SHOW SHOW    
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% VERIFICA LA CONSISTENZA DEL SISTEMA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sistema = VERIFICA_LA_CONSISTENZA_DEL(Sistema);
if strcmp(Sistema.Schema_Consistente,'No')
    return
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% ORIENTAMENTO DEI RAMI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sistema = ORIENTAMENTO_DEI_RAMI(Sistema);
if strcmp(Sistema.Rami_Orientati,'No')
    return
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% COSTRUZIONE DEL MODELLO DINAMICO NELLO SPAZIO DEGLI STATI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
syms XX LL AA
XX(1:Nr_dei_Rami)=0;                     % Vettore delle variabili di stato X
AA(1:Nr_dei_Rami,1:Nr_dei_Rami)=0;       % Matrice di sistema A
LL(1:Nr_dei_Rami,1:Nr_dei_Rami)=0;       % Matrice energia L
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Sulla diagonale dalla matrice LL vengono memorizzati: 
%%%% a) i parametri Kn per gli elementi dinamici;
%%%% b) le variabili di uscita per gli elementi di tipo ingresso;
%%%% c) nulla per i blocchi di tipo Filo e per i blocchi dissipativi;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Show_Details,'Si'); 
    disp('******************');  
    disp('*** Lista_Rami ***');  
    disp('******************');  
end
for ii=(1:Nr_dei_Rami)
    if strcmp(Show_Details,'Si'); disp(['Ramo nr. ' num2str(ii)]); SHOW_RAMO(Lista_Rami(ii)); end           %%%% SHOW SHOW SHOW
    if strcmp(Lista_Rami(ii).Out,'Effort')
        XX(ii)=Lista_Rami(ii).E_name;           % Variabile di stato Effort
    elseif strcmp(Lista_Rami(ii).Out,'Flow')
        XX(ii)=Lista_Rami(ii).F_name;           % Variabile di stato Flow
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    AA(ii,abs(Lista_Rami(ii).Rami_Input))=sign(Lista_Rami(ii).Rami_Input);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    switch Lista_Rami(ii).Tipo_di_Ramo
        case 'Filo'                            
            %%% Per blocchi di tipo Filo la riga ii nelle matrici L ed A rimane vuota
        case 'Ingresso'
            if strcmp(Lista_Rami(ii).Out,'Effort')
                LL(ii,ii)=Lista_Rami(ii).F_name;            % Variabile di uscita Flow
            elseif strcmp(Lista_Rami(ii).Out,'Flow')
                LL(ii,ii)=Lista_Rami(ii).E_name;            % Variabile di uscita Effort
            end
        case 'Dinamico'
            if strcmp(Lista_Rami(ii).Diretto,'Si')      
                LL(ii,ii)=Lista_Rami(ii).K_name;            % Blocco Dinamico 'Diretto'
            elseif strcmp(Lista_Rami(ii).Diretto,'No')
                LL(ii,ii)=1/Lista_Rami(ii).K_name;          % Blocco Dinamico 'Inverso'
            end
        case 'Resistivo'  
            if strcmp(Lista_Rami(ii).Diretto,'Si')          % Blocco Resistivo 'Diretto'
                if strcmp(Lista_Rami(ii).Out,'Effort')
                    AA(ii,ii)=-1/Lista_Rami(ii).K_name;     % Resistenza in parallelo ad un elemento Effort
                elseif strcmp(Lista_Rami(ii).Out,'Flow')
                    AA(ii,ii)=-Lista_Rami(ii).K_name;       % Resistenza in serie ad un elemento Flow
                end
            elseif strcmp(Lista_Rami(ii).Diretto,'No')      % Blocco Resistivo 'Inverso'
                if strcmp(Lista_Rami(ii).Out,'Effort')
                    AA(ii,ii)=-Lista_Rami(ii).K_name;       % Conduttanza in parallelo ad un elemento Effort
                elseif strcmp(Lista_Rami(ii).Out,'Flow')
                    AA(ii,ii)=-1/Lista_Rami(ii).K_name;     % Conduttanza in serie ad un elemento Flow
                end
            end
        otherwise
    end
end
%%%%
if strcmp(Show_Details,'Si'); disp('Le='); disp(LL);  disp('Ae='); disp(AA);  disp('Xe='); disp(XX); end            %%%% SHOW SHOW SHOW
%%%%
for ii=find([Lista_Rami.Pow_In]==-1)            % Pow_In=-1 -> La potenza esce dal ramo
    if strcmp(Lista_Rami(ii).Out,'Effort')
        AA(ii,:)=-AA(ii,:);
    elseif strcmp(Lista_Rami(ii).Out,'Flow')
        AA(:,ii)=-AA(:,ii);
    end
end
% %%%%
% if strcmp(Show_Details,'Si'); disp('Ae='); disp(AA); end            %%%% SHOW SHOW SHOW
%%%%
X_typ={Lista_Rami.Tipo_di_Ramo};            % Tipo di variabile
pos_x=find(strcmp(X_typ,'Dinamico'));     	% Posizione delle variabili di stato 'x'     
pos_z=find(strcmp(X_typ,'Resistivo'));     	% Posizione delle variabili impedenza 'z'
pos_u=find(strcmp(X_typ,'Ingresso'));       % Posizione delle variabili di ingresso 'u'
pos_xz=[pos_x pos_z];                       % Prima le variabili di stato 'x' e poi le impedenze 'z'
%%%%
YY=diag(LL(pos_u,pos_u));             % Vettore delle uscite del sistema "espanso"
LL=LL(pos_xz,pos_xz);                 % Matrice energia del sistema "espanso"
BB=AA(pos_xz,pos_u);                  % Matrice degli ingressi del sistema "espanso"
CC=AA(pos_u,pos_xz);                  % Matrice di uscita del sistema "espanso"
DD=AA(pos_u,pos_u);                   % Matrice ingresso-uscita del sistema "espanso"
AA=AA(pos_xz,pos_xz);                 % Matrice di potenza del sistema "espanso"
UU=XX(pos_u).';                       % Vettore degli ingressi del sistema "espanso"
XX=XX(pos_x).';                       % Vettore di stato del sistema "espanso"
%%%%
if strcmp(Show_Details,'Si'); disp('LL='); disp(LL);  disp('AA='); disp(AA);  disp('BB='); disp(BB);  disp('CC='); disp(CC); end   %%%% SHOW SHOW SHOW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SOSTITUZIONE DI ALCUNE VARIABILI CON VALORI FORNITI DALL'ESTERNO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii=1:size((Sistema.Rimpiazza),1)
    Str_1=Sistema.Rimpiazza{ii,1};
%     Str_2=subs(Sistema.Rimpiazza(ii,2));
    Str_2=Sistema.Rimpiazza{ii,2};
    switch Str_2(1)
        case {'I','0','1','2','3','4','5','6','7','8','9'}
            eval([Str_1 '= eval(Str_2);']);            
            LL=sym(subs(LL));
            AA=sym(subs(AA));
            BB=sym(subs(BB));
            CC=sym(subs(CC));
            DD=sym(subs(DD));
            XX=sym(subs(XX));
            YY=sym(subs(YY));
        otherwise
            eval(['syms ' Str_2])
            eval([Str_2 '=subs(' Str_2 ');'])
            LL=subs(LL,Str_1,Str_2);
            AA=subs(AA,Str_1,Str_2);
            BB=subs(BB,Str_1,Str_2);
            CC=subs(CC,Str_1,Str_2);
            DD=subs(DD,Str_1,Str_2);
            XX=subs(XX,Str_1,Str_2);
            YY=subs(YY,Str_1,Str_2);
    end
end
Nr_x=length(pos_x);                     % Numero delle variabili di stato
Nr_u=sum(strcmp(X_typ,'Ingresso'));  	% Numero dei VERI ingressi 
%%%%
A21=AA(Nr_x+1:end,1:Nr_x);
A22=AA(Nr_x+1:end,Nr_x+1:end);
B2=BB(Nr_x+1:end,:);
if strcmp(Show_Details,'Si'); disp('A21='); disp(A21);  disp('A22='); disp(A22);  disp('B2='); disp(B2); end   %%%% SHOW SHOW SHOW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LA SEGUENTE PARTE SERVE PER RIDURRE IL SISTEMA QUANDO LA MATRICE A22
%%% NON E' A RANGO PIENO A SEGUITO DELLE VARIABILI RIMPIAZZATE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Riduci=1;
while Riduci==1
    Riduci=0;
    Nr_A22=size(A22,2);
    for ii=(1:Nr_A22)
        if sum(abs(A22(ii,:)))==0
            ind=find(A21(ii,:)~=0);
            jj=ind(end);            % Le variabili jj e Nr_x+ii vengono eliminate:
            Nr_A=size(AA,1);        %    la variabile jj e' funzione delle altre,
            T=eye(Nr_A);            %    la variabile Nr_x+ii non serve perch� fittizia
            T(jj,:)=-AA(Nr_x+ii,:)/AA(Nr_x+ii,jj);
            T=T(:,[1:jj-1 jj+1:Nr_x+ii-1 Nr_x+ii+1:Nr_A]);  % Toglie le colonne jj e Nr_x+ii 
            XX=XX([1:jj-1 jj+1:Nr_x]);    % Viene tolta la jj-sima variabile di stato
            LL=simple(T.'*LL*T);
            AA=simple(T.'*AA*T);
            BB=T.'*BB;              % Il procedimento funziona dolo se la matrice B22 � nulla
            CC=CC*T;
            Nr_x=Nr_x-1;            % Una vera variabile di stato � stata eliminata
            A21=AA(Nr_x+1:end,1:Nr_x);
            A22=AA(Nr_x+1:end,Nr_x+1:end);
            B2=BB(Nr_x+1:end,:);
            Riduci=1;
            if strcmp(Show_Details,'Si'); disp('A21='); disp(A21);  disp('A22='); disp(A22);  disp('B2='); disp(B2); end   %%%% SHOW SHOW SHOW
            break
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if not(isempty(A21))
    T=[  eye(Nr_x)   ; ...          % Matrici di trasformazione
        -inv(A22)*A21];             %   x = T*x' + Tb*u
    LT=T.'*LL*T;                    % Matrice energia del sistema "ridotto"
    AT=simple(T.'*AA*T);            % Matrice di potenza del sistema "ridotto"
    if isempty(B2)
        BT=[];                      % Matrice degli ingressi del sistema "ridotto"
        CT=[];                      % Matrice di uscita del sistema "ridotto"
        DT=[];                      % Matrice ingresso-uscita del sistema "ridotto"
    else
        Tb=[zeros(Nr_x,Nr_u); ...  	%
                 -inv(A22)*B2];    	%
        CT=simple(CC*T);          	% Matrice di uscita del sistema "ridotto"
        BT=simple(T.'*(BB+AA*Tb));	% Matrice degli ingressi del sistema "ridotto"
        DT=simple(DD+CC*Tb);       	% Matrice ingresso-uscita del sistema "ridotto"
    end
elseif isempty(A22)
    LT=LL;                          % Matrice energia del sistema "ridotto"
    AT=AA;                          % Matrice di potenza del sistema "ridotto"
    CT=CC;                          % Matrice di uscita del sistema "ridotto"
    BT=BB;                          % Matrice degli ingressi del sistema "ridotto"
    DT=simple(DD);                  % Matrice ingresso-uscita del sistema "ridotto"
else
    LT=[];                          % Matrice energia del sistema "ridotto"
    AT=[];                          % Matrice di potenza del sistema "ridotto"
    BT=[];                          % Matrice degli ingressi del sistema "ridotto"
    CT=[];                          % Matrice di uscita del sistema "ridotto"
    Tb=[zeros(Nr_x,Nr_u);-inv(A22)*B2];
    DT=simple(DD+CC*Tb);        	% Matrice ingresso-uscita del sistema "ridotto"
end
XT=XX;                             	% Vettore di stato  del sistema "ridotto"
UT=UU;                             	% Vettore degli ingressi del sistema "ridotto"
YT=YY;                            	% Vettore delle uscite del sistema "ridotto"
%%%%%%%% SHOW SHOW SHOW
if not(isempty([Lista_Rami.TR_o_GY]))
    if strcmp(Show_Details,'Si'); 
        disp('LT='); disp(LT);  disp('AT='); disp(AT);  disp('BT='); disp(BT);  disp('CT='); disp(CT); 
    end   
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%  GESTIONE DI EVENTUALI TRASFORMATORI E GIRATORI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Nr_Ingr=length(pos_u);
FT=sym(zeros(Nr_Ingr,Nr_Ingr));
GT=zeros(Nr_Ingr,Nr_Ingr);
for ii=1:Nr_Ingr
    Ramo_ii=pos_u(ii);
    if isempty(Lista_Rami(Ramo_ii).TR_o_GY)
        GT(ii,ii)=1; 
    else
        if Lista_Rami(Ramo_ii).Gemello==-1
            Kn = CALCOLA_PARAMETRO_KN_DI_T_G(Lista_Rami(Ramo_ii));
            FT(ii-1,ii) = Kn;
            FT(ii,ii-1) = Kn;
        end
    end
end
%%%% AUTORETROAZIONE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if Nr_Ingr>0
    GT=GT(:,diag(GT)==1);
    Delta=inv(eye(Nr_Ingr)-FT*DT);
    AT=AT+BT*Delta*FT*CT;
    BT=BT*Delta*GT;
    CT=GT.'*(CT+DT*Delta*FT*CT);
    DT=GT.'*DT*Delta*GT;
    YT=GT.'*YT;
    UT=GT.'*UT;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%  GESTIONE DI PARAMETRI NELLA MATRICE A CON VALORE TENDENTE ALL'INFINITO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if not(isempty(XT))
    AT1=subs(AT,'Inf',0);         % Verifica se in A ci sono elementi Inf
    AT2=subs(AT-AT1,'Inf',1);     %
    [ii,jj]=find(AT2~=0);           %
    ii=unique(ii); jj=unique(jj);   %
else ii=[]; 
end
if not(isempty(UT))
    BT1=subs(BT,'Inf',0);         % Verifica se in B ci sono elementi Inf
    BT2=subs(BT-BT1,'Inf',1);     %
    hh=find(BT2(ii)~=0, 1);         %
else hh=[]; 
end
if not(isempty(ii))&&isempty(hh)
    AT3=AT2(ii,jj);
    NV=null(AT3);               % Nullo della matrice AT3
    TN=eye(length(XT));
    for hh=1:size(NV,2)
        Ind=find(NV(:,hh)~=0);
        NV(:,hh)=NV(:,hh)/NV(Ind(1),hh);
        TN(ii(Ind),jj(Ind(1)))=NV(Ind,hh);
        TN(:,jj(Ind(2:end)))=0;
        Str=['Vincolo tra le variabili di stato: ' char(XT(ii(Ind(1))))];
        for kk=2:length(Ind)
            Str=[Str ' = ' char(XT(ii(Ind(kk))))];
        end
        disp(Str); disp(' '); % beep
    end
    Keep=diag(TN)==1;
    TN=TN(:,Keep);
    XT=XT(Keep);
    AT=TN'*AT*TN;               % Calcolo del sistema ridotto
    LT=TN'*LT*TN;               %
    if not(isempty(UT))         %
        BT=TN'*BT;              %
        CT=CT*TN;               %
    end                         %
end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%% LA SEGUENTE PARTE SERVE PER RIDURRE IL SISTEMA QUANDO LA MATRICE LL
% %%% NON E' A RANGO PIENO A SEGUITO DELLE VARIABILI RIMPIAZZATE
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nr_L=size(LT,1);            % 
% Ind=find(diag(LT)==0);
% No_Ind=setdiff(1:Nr_L,Ind);
% T=eye(Nr_L);                % 
% T=[T(:,No_Ind) T(:,Ind)];
% % Riduci=1;
% % while Riduci==1
% %     Riduci=0;
% %     Nr_A22=size(A22,2);
% %     for ii=(1:Nr_A22)
% %         if sum(abs(A22(ii,:)))==0
% %             ind=find(A21(ii,:)~=0);
% %             jj=ind(end);            % Le variabili jj e Nr_x+ii vengono eliminate:
% %             Nr_A=size(AA,1);        %    la variabile jj e' funzione delle altre,
% %             T=eye(Nr_A);            %    la variabile Nr_x+ii non serve perch� fittizia
% %             T(jj,:)=-AA(Nr_x+ii,:)/AA(Nr_x+ii,jj);
% %             T=T(:,[1:jj-1 jj+1:Nr_x+ii-1 Nr_x+ii+1:Nr_A]);  % Toglie le colonne jj e Nr_x+ii 
% %             XX=XX([1:jj-1 jj+1:Nr_x]);    % Viene tolta la jj-sima variabile di stato
% %             LL=simple(T.'*LL*T);
% %             AA=simple(T.'*AA*T);
% %             BB=T.'*BB;              % Il procedimento funziona dolo se la matrice B22 � nulla
% %             CC=CC*T;
% %             Nr_x=Nr_x-1;            % Una vera variabile di stato � stata eliminata
% %             A21=AA(Nr_x+1:end,1:Nr_x);
% %             A22=AA(Nr_x+1:end,Nr_x+1:end);
% %             B2=BB(Nr_x+1:end,:);
% %             Riduci=1;
% %             if strcmp(Show_Details,'Si'); disp('A21='); disp(A21);  disp('A22='); disp(A22);  disp('B2='); disp(B2); end   %%%% SHOW SHOW SHOW
% %             break
% %         end
% %     end
% % end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%  SALVA LE MATRICI DEL SISTEMA DESCRITTO NELLO SPAZIO DEGLI STATI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sistema.Equazioni_SS.L=LT;
Sistema.Equazioni_SS.A=AT;
Sistema.Equazioni_SS.B=BT;
Sistema.Equazioni_SS.C=CT;
Sistema.Equazioni_SS.D=DT;
Sistema.Equazioni_SS.X=XT;
Sistema.Equazioni_SS.U=UT;
Sistema.Equazioni_SS.Y=YT;
%%%
Sistema.Schema_Analizzato='Si';
Sistema.Lista_Nodi=Lista_Nodi;
Sistema.Lista_Rami=Lista_Rami;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% MOSTRA LE MATRICI E I VETTORI DI SISTEMA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MOSTRA_ABC(Sistema)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% MOSTRA LA PARTE SIMMETRICA ED EMISIMMETRICA DELLA MATRICE A
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Sistema.Show_Skew,'Si')
    disp('Parte simmetrica della matrice A:')
    disp(' ')
    disp(simplify((AT+AT.')/2))    
    disp('Parte emisimmetrica della matrice A:')
    disp(' ')
    disp(simplify((AT-AT.')/2))
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% MOSTRA LA MATRICE DI TRASFERIMENTO H(s) DEL SISTEMA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Sistema.Show_Hs,'Si')
    syms s
    Hs=simplify(CT*inv(LT*s-AT)*BT+DT); % Matrice di trasferimento
    Sistema.Hs=Hs;
    Delta=simplify(det(LT*s-AT));       % Geterminante del grafo
    Sistema.Delta=Delta;
    disp('Symbolic form of the Transfer matrix H(s)=C*inv(L*s-A)*B+D:')
    disp(Hs)
    disp('Symbolic form of the block scheme Determinant Delta=det(LT*s-AT):')
    disp(Delta)
    %%%%%%% Calcolo dei valori numerici dei parametri
    Parametri=Sistema.Parametri;
    for ii=1:length(Parametri)
        if strcmp(Parametri(ii).Type,'Kn0')
            eval([Parametri(ii).Nome '=' num2str(Parametri(ii).Value) ';'])
        end
    end      
    %%%%%%%
    Sistema.Hs_N=subs(Hs);
    Sistema.Delta_N=subs(Delta);
    disp('Numeric form of the Transfer matrix H(s):')
    disp(Sistema.Hs_N)
    disp('Numeric form of the Determinant Delta:')
    disp(Sistema.Delta_N)
    %%%%%%%%%%%%%%%%%%%%%%%%%%
end
return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function  [LT,AT,BT,CT,DT,XT,UT,YT] = POG_SS_TRANSFORMSTION(LL,AA,BB,CC,DD,XX,UU,YY,T)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LT=simple(T.'*LL*T);
% AT=simple(T.'*AA*T);
% BT=T.'*BB;              
% CT=CC*T;
% XT=T.'*XX;
% DT=DD;
% UT=UU;
% YT=YY;
% return
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Kn = CALCOLA_PARAMETRO_KN_DI_T_G(Ramo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if Ramo.TR_o_GY=='T'
    if strcmp(Ramo.Out,'Flow')
        if strcmp(Ramo.Diretto,'Si')
            Kn = Ramo.K_name;
        else
            Kn = 1./Ramo.K_name;
        end
    else
        if strcmp(Ramo.Diretto,'Si')
            Kn = 1./Ramo.K_name;
        else
            Kn = Ramo.K_name;
        end
    end
elseif Ramo.TR_o_GY=='G'
    if strcmp(Ramo.Out,'Flow')
        if strcmp(Ramo.Diretto,'Si')
            Kn = 1./Ramo.K_name;
        else
            Kn = Ramo.K_name;
        end
    else
        if strcmp(Ramo.Diretto,'Si')
            Kn = Ramo.K_name;
        else
            Kn = 1./Ramo.K_name;
        end
    end
end
return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function  Kn = CALCOLA_PARAMETRO_KN_DI_T_G(Ramo)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if strcmp(Ramo.Out,'Flow')
%     Kn = Ramo.K_name;
% else
%     Kn = 1./Ramo.K_name;
% end
% if Ramo.TR_o_GY=='G'
%     Kn = 1./Kn;
% end
% if strcmp(Ramo.Diretto,'No')
%     Kn = 1./Kn;
% end
% return
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Sistema = VERIFICA_LA_CONSISTENZA_DEL(Sistema)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global Lista_Rami  
Sistema.Schema_Consistente='No';
Rami_Utili=Sistema.Rami_Utili;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% VERIFICA SUI RAMI IN SERIE/PARALLELO: SI GENERA UN ERRORE SE DUE RAMI 
%%%% EFFORT SONO IN PARALLELO O DUE RAMI FLOW SONO IN SERIE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii=Rami_Utili
    switch Lista_Rami(ii).Out
        case 'Effort'
            Lista_Rami(ii).Out='Flow';
            Rami_Input=PERCORSO_EFFORT(ii);
            Lista_Rami(ii).Out='Effort';
        case 'Flow'
            Lista_Rami(ii).Out='Effort';
            Rami_Input = PERCORSO_FLOW(ii);
            Lista_Rami(ii).Out='Flow';
        otherwise
            Rami_Input=[];
    end
    if not(isempty(Rami_Input))
        Stringa=['I rami ' num2str(ii) '-' Lista_Rami(ii).Nome_Ramo ' e [' ...
            num2str(Rami_Input) '] sono di tipo ''' Lista_Rami(ii).Out ''' e sono in serie/parallelo'];
        SHOW_ERRORE(Sistema,Stringa)
        return
    end
end
Sistema.Schema_Consistente='Si';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function   Rami_Input = PERCORSO_EFFORT(ii_Ramo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global Lista_Rami Lista_Nodi Nodi_non_Visitati Verifica_Old
Nodo_From=Lista_Rami(ii_Ramo).From;
Nodo_End=Lista_Rami(ii_Ramo).To;
Nodi_non_Visitati=setdiff(unique([Lista_Nodi.Nome]),Nodo_End);
Rami_Input = NESTED_EFFORT(Nodo_From,Nodo_End);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Verifica_Old,'Si')
    %%%%% VECCHIA VERSIONE
    Nodi_non_Visitati=unique([Lista_Nodi.Nome]);
    Rami_Input_Old = NESTED_EFFORT_OLD(ii_Ramo,Lista_Rami(ii_Ramo).From);
    %%%%% VERIFICA
    if not(isequal(sort(Rami_Input_Old),sort(Rami_Input)))
        beep; disp('**'); disp([ii_Ramo Rami_Input_Old]); disp([ii_Ramo Rami_Input])
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function   Rami_Input = NESTED_EFFORT(Nodo_From,Nodo_End)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global Lista_Rami Lista_Nodi Nodi_non_Visitati
Rami_Input=[];
Next_Tocca_Nodo_End=find(Lista_Nodi(Nodo_From).Next_Nodi==Nodo_End);
Rami_che_Toccano_il_Nodo_End=abs(Lista_Nodi(Nodo_From).Next_Rami(Next_Tocca_Nodo_End));
if not(isempty(Rami_che_Toccano_il_Nodo_End))
    Puntatori_a_Rami_Effort=find(strcmp({Lista_Rami(Rami_che_Toccano_il_Nodo_End).Out},'Effort'));
    if not(isempty(Puntatori_a_Rami_Effort))
        Rami_Input=Lista_Nodi(Nodo_From).Next_Rami(Next_Tocca_Nodo_End(Puntatori_a_Rami_Effort));
        return
    end
end
Nodi_non_Visitati=setdiff(Nodi_non_Visitati,Nodo_From);
Next_Nodi=Lista_Nodi(Nodo_From).Next_Nodi;
Next_Rami=Lista_Nodi(Nodo_From).Next_Rami;
for ii=1:length(Next_Nodi);
    Nodo_ii=Next_Nodi(ii);
    Rami_ii=Next_Rami(ii);
    Next_Tipo=Lista_Rami(abs(Rami_ii)).Out;
    if ismember(Nodo_ii,Nodi_non_Visitati)&&(strcmp(Next_Tipo,'Effort')) 
        Rami_Input_Next = NESTED_EFFORT(Nodo_ii,Nodo_End);
        if not(isempty(Rami_Input_Next))
            Rami_Input=[Rami_ii Rami_Input_Next ];
            break
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function   Rami_Input = NESTED_EFFORT_OLD(ii_Ramo,jj_Nodo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global Lista_Rami Lista_Nodi Nodi_non_Visitati
Rami_Input=[];
Ramo=Lista_Rami(ii_Ramo);
Nodi_From_To=[Ramo.From Ramo.To];
Ramo_Tocca_il_Nodo=ismember(jj_Nodo,Nodi_From_To);
if (strcmp(Ramo.Out,'Effort'))&&(Ramo_Tocca_il_Nodo)
    if Ramo.From==jj_Nodo
        Rami_Input=ii_Ramo;
    end
    if Ramo.To==jj_Nodo
        Rami_Input=-ii_Ramo;
    end
end
if (not(strcmp(Ramo.Out,'Effort'))&&(Ramo_Tocca_il_Nodo))||((strcmp(Ramo.Out,'Effort'))&&~(Ramo_Tocca_il_Nodo))
    Next_Nodo=intersect(setdiff(Nodi_From_To,jj_Nodo),Nodi_non_Visitati);
    if not(isempty(Next_Nodo))
        Nodi_non_Visitati=setdiff(Nodi_non_Visitati,Next_Nodo);
        Next_Rami=setdiff(Lista_Nodi(unique([Lista_Nodi.Nome])==Next_Nodo).Next_Rami,[ii_Ramo,-ii_Ramo]);
        for ramo_i=Next_Rami
            ramo_ii=abs(ramo_i);
            Rami_Input_Next = NESTED_EFFORT_OLD(ramo_ii,jj_Nodo);
            if not(isempty(Rami_Input_Next))
                Rami_Input=[Rami_Input_Next -ramo_i];
                [~,RI,~]=unique(Rami_Input);
                Rami_Input=Rami_Input(sort(RI));
                break
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function   Rami_Input = PERCORSO_FLOW(ii_Ramo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global Lista_Rami Lista_Nodi Nodi_non_Visitati Verifica_Old
Nodi_non_Visitati=unique([Lista_Nodi.Nome]);
Rami_Input = NESTED_FLOW(ii_Ramo,Lista_Rami(ii_Ramo).To);
if isempty(Rami_Input)
    Nodi_non_Visitati=unique([Lista_Nodi.Nome]);
    Rami_Input = -NESTED_FLOW(ii_Ramo,Lista_Rami(ii_Ramo).From);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Verifica_Old,'Si')
    %%%%% VECCHIA VERSIONE
    Nodi_To_From=[Lista_Rami(ii_Ramo).To Lista_Rami(ii_Ramo).From];
    for ii=1:2
        Nodi_non_Visitati=unique([Lista_Nodi.Nome]);
        Rami_Input_Old = (-1)^ii*NESTED_FLOW_OLD(ii_Ramo,Nodi_To_From(ii));
        if not(isempty(Rami_Input_Old))
            break
        end
    end
    %%% VERIFICA
    if not(isequal(sort(Rami_Input_Old),sort(Rami_Input)))
        beep; disp('**');  disp([ii_Ramo Rami_Input_Old]); disp([ii_Ramo Rami_Input])
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function   Rami_Input = NESTED_FLOW(Ramo,Nodo_To)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global Lista_Rami Lista_Nodi Nodi_non_Visitati
Rami_Input=[];
Nodi_non_Visitati=setdiff(Nodi_non_Visitati,Nodo_To);
Puntatori_Next_Nodi=find(abs(Lista_Nodi(Nodo_To).Next_Rami)~=Ramo);
Next_Nodi=Lista_Nodi(Nodo_To).Next_Nodi(Puntatori_Next_Nodi);
Next_Rami=Lista_Nodi(Nodo_To).Next_Rami(Puntatori_Next_Nodi);
for ii=1:length(Next_Rami);
    Ramo_ii=Next_Rami(ii);
    Nodo_ii=Next_Nodi(ii);
    Next_Tipo=Lista_Rami(abs(Ramo_ii)).Out;
    if strcmp(Next_Tipo,'Flow')
        Rami_Input=[Ramo_ii Rami_Input];    
    elseif ismember(Nodo_ii,Nodi_non_Visitati) 
        Rami_Input_Next = NESTED_FLOW(abs(Ramo_ii),Nodo_ii);
        if not(isempty(Rami_Input_Next))
            Rami_Input=[Rami_Input Rami_Input_Next];
        else
            Rami_Input=[];
            break
        end
    end
end
%%%%%  ELIMINA LE COPPIE (+N,-N) ALL'INTERNO DI "Rami_Input"
Rami_Input = TOGLI_LE_COPPIE_pm_N(Rami_Input);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function   Rami_Input = NESTED_FLOW_OLD(ii_Ramo,jj_Nodo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global Lista_Rami Lista_Nodi Nodi_non_Visitati
Rami_Input=[];
Ramo=Lista_Rami(ii_Ramo);
Nodi_From_To=[Ramo.From Ramo.To];
if strcmp(Ramo.Out,'Flow')
    if Ramo.From==jj_Nodo
        Rami_Input=ii_Ramo;
    end
    if Ramo.To==jj_Nodo
        Rami_Input=-ii_Ramo;
    end
else
    Next_Nodo=intersect(setdiff(Nodi_From_To,jj_Nodo),Nodi_non_Visitati);
    if not(isempty(Next_Nodo))
        Nodi_non_Visitati=setdiff(Nodi_non_Visitati,Next_Nodo);
%         Ind=find([Lista_Nodi.Nome]==Next_Nodo);
%         for Ind_ii=Ind
%             Ind_Next_Nodo=Ind_ii;
%             if not(isempty(Lista_Nodi(Ind_Next_Nodo).Next_Rami))
%                 break
%             end
%         end
%         Next_rami=setdiff(Lista_Nodi(Ind_Next_Nodo).Next_Rami,[ii_Ramo,-ii_Ramo]);
        Next_rami=setdiff(Lista_Nodi(unique([Lista_Nodi.Nome])==Next_Nodo).Next_Rami,[ii_Ramo,-ii_Ramo]);
        for ramo_i=Next_rami
            ramo_ii=abs(ramo_i);
            Rami_Input_Next = NESTED_FLOW_OLD(ramo_ii,Next_Nodo);
            if isempty(Rami_Input_Next)
                Rami_Input=[];
                break
            end
            [x_rami,IA,IB]=setxor(Rami_Input,-Rami_Input_Next);
            if not(isempty(x_rami))
                Rami_Input=Rami_Input(sort(IA));
                Rami_Input_Next=Rami_Input_Next(sort(IB));
            end
            Rami_Input=[Rami_Input Rami_Input_Next];
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function   Sistema = ORIENTAMENTO_DEI_RAMI(Sistema)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global Lista_Rami 
Sistema.Rami_Orientati='No';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% CALCOLO DI TUTTI E SOLI I RAMI DI TIPO "ELABORAZIONE"
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Rami_di_tipo_Filo=find(strcmp({Lista_Rami.Tipo_di_Ramo},'Filo'));
Rami_Elaborazione=1:Sistema.Nr_dei_Rami;                            % Tutti i rami
Rami_Elaborazione=setdiff(Rami_Elaborazione,Rami_di_tipo_Filo);    	% Si tolgono i rami di tipo filo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% ORIENTAMENTO "CAUSALE" DEI RAMI DI TIPO "ELABORAZIONE"
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Rami_Input_da_Orientare=Rami_Elaborazione;
Ramo_Nr=0;
Ramo_Tipo='Vuoto';
while not(isempty(Rami_Input_da_Orientare))
    Rami_Input_Orientati=[];
    for ii_Ramo=Rami_Input_da_Orientare
        switch Lista_Rami(ii_Ramo).Out
            case 'Effort'
                Rami_Input = PERCORSO_FLOW(ii_Ramo);
            case 'Flow'
                Rami_Input = PERCORSO_EFFORT(ii_Ramo);
            otherwise
                Lista_Rami(ii_Ramo).Out='Flow';
                Rami_Input = PERCORSO_EFFORT(ii_Ramo);
                if isempty(Rami_Input)
                    Lista_Rami(ii_Ramo).Out='Effort';
                    Rami_Input = PERCORSO_FLOW(ii_Ramo);
                    if isempty(Rami_Input)
                        Lista_Rami(ii_Ramo).Out='Vuoto';
                    end
                end
        end
        if not(isempty(Rami_Input))
            Lista_Rami(ii_Ramo).Rami_Input=Rami_Input;
            if length(unique(abs(Rami_Input)))~=length(Rami_Input)
                beep; 
                disp([Lista_Rami(ii_Ramo).Out ' ' num2str(ii_Ramo) ' -> '  num2str(Rami_Input)])
            end
            Rami_Input_Orientati=[Rami_Input_Orientati ii_Ramo];
            %%% ORIENTAMENTO DEL RAMO GEMELLO
            Ramo_Gemello=ii_Ramo+Lista_Rami(ii_Ramo).Gemello;
            if not(isempty(Ramo_Gemello))
                TR_o_GY=Lista_Rami(ii_Ramo).TR_o_GY;
                Out=Lista_Rami(ii_Ramo).Out;
                Out_Gemello=Lista_Rami(Ramo_Gemello).Out;
                if TR_o_GY=='T'
                    if strcmp(Out,'Effort')
                        New_Out_Gemello='Flow';
                    elseif strcmp(Out,'Flow')
                        New_Out_Gemello='Effort';
                    end
                elseif TR_o_GY=='G'
                    New_Out_Gemello=Out;
                end
                if strcmp(Out_Gemello,'Vuoto')||strcmp(Out_Gemello,New_Out_Gemello)
                    Lista_Rami(Ramo_Gemello).Out=New_Out_Gemello;
                else
                    beep; disp('I blocchi gemelli sono orientati in modo errato')
                    disp(['Blocco connessione: ' num2str(ii_Ramo) '->' TR_o_GY])
                    disp(['Primo ramo gemello: ' num2str(ii_Ramo) '->' Out])
                    disp(['Secondo ramo gemello: ' num2str(Ramo_Gemello) '->' Out_Gemello])
                end
            end
        end
    end
    if isempty(Rami_Input_Orientati)
        Rami_Tipo_da_Orientare=find(strcmp({Lista_Rami.Out},'Vuoto'));
        if isempty(Rami_Tipo_da_Orientare)
            Sistema.Lista_Rami=Lista_Rami;
            Stringa='Schema non consistente e Rami_Tipo_da_Orientare = empty';
            SHOW_ERRORE(Sistema,Stringa)            
            return
        end
        switch Ramo_Tipo
            case 'Vuoto'                    % Il primo ramo � orientato Effort
                Ramo_Tipo='Effort';
                Ramo_Nr=Rami_Tipo_da_Orientare(1);
                Lista_Rami(Ramo_Nr).Out='Effort';
                Nr_Tipo=length(Rami_Tipo_da_Orientare);
            case 'Effort'
                if length(Rami_Tipo_da_Orientare)==(Nr_Tipo-1)
                    Ramo_Tipo='Flow';      % Effort non va bene per cui si prova Flow
                    Lista_Rami(Ramo_Nr).Out='Flow';
                else
                    disp(['Il ramo ' num2str(Ramo_Nr) ' � stato orientato ''' Ramo_Tipo ''''])
                    Ramo_Tipo='Effort';      % Di nuovo il primo ramo � orientato Effort
                    Ramo_Nr=Rami_Tipo_da_Orientare(1);
                    Lista_Rami(Ramo_Nr).Out='Effort';
                    Nr_Tipo=length(Rami_Tipo_da_Orientare);
                end
            case 'Flow'
                if length(Rami_Tipo_da_Orientare)==(Nr_Tipo-1)
                    % 
                    Lista_Rami(Ramo_Nr).Out='Vuoto';
                    Rami_Tipo_da_Orientare=[Ramo_Nr Rami_Tipo_da_Orientare];
                    %
                    Sistema.Lista_Rami=Lista_Rami;
                    Stringa='Schema non consistente';
                    SHOW_ERRORE(Sistema,Stringa)
                    disp('Rami da Orientare come Ingresso:')
                    disp(Rami_Input_da_Orientare)
                    %
                    disp('Rami da Orientare come Tipo:')
                    disp(Rami_Tipo_da_Orientare)
                    return
                else
                    disp(['Il ramo ' num2str(Ramo_Nr) ' � stato orientato ''' Ramo_Tipo ''''])
                    Ramo_Tipo='Effort';          % Di nuovo il primo ramo � orientato Effort
                    Ramo_Nr=Rami_Tipo_da_Orientare(1);
                    Lista_Rami(Ramo_Nr).Out='Effort';
                    Nr_Tipo=length(Rami_Tipo_da_Orientare);
                end
        end
    end
    Rami_Input_da_Orientare=setdiff(Rami_Input_da_Orientare,Rami_Input_Orientati);
    if isempty(Rami_Input_da_Orientare)&&(not(strcmp(Ramo_Tipo,'Vuoto')))
        % Si mostra qual � stato l'ultimo ramo orientato
        disp(['Il ramo ' num2str(Ramo_Nr) ' � stato orientato ''' Ramo_Tipo ''''])
    end
    if strcmp(Sistema.Show_Details,'Si'); 
        if not(isempty(Rami_Input_da_Orientare))
            disp('Rami_da_Orientare = '); disp(Rami_Input_da_Orientare);
        end
    end               %%%% SHOW SHOW SHOW
end
Sistema.Rami_Orientati='Si';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  MOSTRA_ABC(Sistema)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Sistema.Salva_EQN_Diff_Eqs,'Si')
    File=[Sistema.Grafico.Dir_out Sistema.Grafico.Nome_del_grafico '_EQN.txt'];
else
    File='';
end
Equazioni_In=Sistema.Equazioni_SS;
Nr_Eq=size(Equazioni_In.L,1);
if Nr_Eq>=0                 % n>=0 se le equazioni sono state calcolate correttamente
    if not(isempty(File))
        FID=fopen(File,'w');
    else
        FID=0;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%% Le equazioni differenziali vengono memorizzate in formato ascii
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Parametri=Sistema.Parametri;
    Lista='';
    for ii=1:length(Parametri)
        switch Parametri(ii).Type
            case {'Kn0','U','X','Y'}
            Lista=[Lista ' ' Parametri(ii).Nome];
        end
    end
    Lista=[Lista ' s'];
    mydisp('% State space equations:',FID)  
    mydisp('% LM*dot_X = AM*X + BM*U',FID)
    mydisp('%        Y = CM*X + DM*U',FID)
    mydisp(' ',FID)
    mydisp('% Symbolic Parameters of the POG block scheme:',FID)
    mydisp(['syms ' Lista],FID)
    mydisp(' ',FID)
    mydisp('LM = ...    % Energy matrix LM:',FID);mydisp(Equazioni_In.L,FID)
    mydisp('AM = ...    % Power matrix AM:',FID);mydisp(Equazioni_In.A,FID)
    mydisp('BM = ...    % Input matrix BM:',FID);mydisp(Equazioni_In.B,FID)
    mydisp('CM = ...    % Output matrix CM:',FID);mydisp(Equazioni_In.C,FID)
    mydisp('DM = ...    % Input-output matrix DM:',FID);mydisp(Equazioni_In.D,FID)
    mydisp('X  = ...    % State vector X:',FID);mydisp(Equazioni_In.X,FID)
    mydisp('U  = ...    % Input vector U:',FID);mydisp(Equazioni_In.U,FID)
    mydisp('Y  = ...    % Output vector Y:',FID);mydisp(Equazioni_In.Y,FID)
%     mydisp('% Energy matrix LM:',FID)      ;mydisp('L = ...',FID);mydisp(Equazioni_In.L,FID)
%     mydisp('% Power matrix AM:',FID)       ;mydisp('A = ...',FID);mydisp(Equazioni_In.A,FID)
%     mydisp('% Input matrix BM:',FID)       ;mydisp('B = ...',FID);mydisp(Equazioni_In.B,FID)
%     mydisp('% Output matrix CM:',FID)      ;mydisp('C = ...',FID);mydisp(Equazioni_In.C,FID)
%     mydisp('% Input-output matrix DM:',FID);mydisp('D = ...',FID);mydisp(Equazioni_In.D,FID)
%     mydisp('% State vector X:',FID)       ;mydisp('X = ...',FID);mydisp(Equazioni_In.X,FID)
%     mydisp('% Input vector U:',FID)       ;mydisp('U = ...',FID);mydisp(Equazioni_In.U,FID)
%     mydisp('% Output vector Y:',FID)      ;mydisp('Y = ...',FID);mydisp(Equazioni_In.Y,FID)
    mydisp('%%%%%%%%%%  SYMBOLIC TRANSFER MATRIX  %%%%%%%%%%%%%%%%%%%%%',FID)
    mydisp('Hs=CM*inv(s*LM-AM)*BM+DM',FID)
    mydisp(' ',FID)
    mydisp('%%%%%%%%%%%%   NUMERICAL VALUES  %%%%%%%%%%%%%%%%%%%%%%%%%%',FID)
    for ii=1:length(Parametri)
        switch Parametri(ii).Type
            case {'Kn0'}
                mydisp(Parametri(ii).Line,FID)
        end
    end
    mydisp(' ',FID)
    mydisp('%%%%%%%%%%   NUMERIC TRANSFER MATRIX   %%%%%%%%%%%%%%%%%%%%%',FID)
    mydisp('MA=double(eval(sym(inv(LM)*AM)));',FID)
    mydisp('MB=double(eval(sym(inv(LM)*BM)));',FID)
    mydisp('MC=double(eval(sym(CM)));',FID)
    mydisp('MD=double(eval(sym(DM)));',FID)
    mydisp('Sys=ss(MA,MB,MC,MD);',FID)
    mydisp('Hs=tf(Sys)',FID)
    mydisp('% step(Sys)',FID)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%% Le equazioni differenziali vengono memorizzate in formato Latex
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    switch Sistema.Show_Diff_Eqs_Latex
        case 'A'                % Le matrici vengono salvate separatamente
            disp(' ')
            disp('State space equations:')
            disp('\[\left\{\begin{array}{@{}r@{\;}c@{\;}l@{}}')
            disp('\L\,\dot{\x}&=&\A\,\x + \B\,\u\\')
            disp('\y &=& \C\,\x+ \D\,\u')
            disp('\end{array} \right. \]')
            disp('Energy matrix $\L$: \[\L=')
            disp(Filtra_Str(latex(Equazioni_In.L)))
            disp('.\]')
            disp('Power matrix $\A$: \[\A=')
            disp(Filtra_Str(latex(Equazioni_In.A)))
            disp('.\]')
            disp('Input matrix $\B$: \[\B=')
            disp(Filtra_Str(latex(Equazioni_In.B)))
            disp('.\]')
            disp('Output matrix $\C$: \[\C=')
            disp(Filtra_Str(latex(Equazioni_In.C)))
            disp('.\]')
            disp('Input-output matrix $\D$: \[\D=')
            disp(Filtra_Str(latex(Equazioni_In.D)))
            disp('.\]')
            disp('State vector $\x$: \[\x=')
            disp(Filtra_Str(latex(Equazioni_In.X)))
            disp('.\]')
            disp('Input vector $\u$: \[\u=')
            disp(Filtra_Str(latex(Equazioni_In.U)))
            disp('.\]')
            disp('Output vector $\y$: \[\y=')
            disp(Filtra_Str(latex(Equazioni_In.Y)))
            disp('.\]')
            disp(' ')
        case 'AB'               % Le matrici vengono salvate a coppie
            disp(' ')
            disp('State space equations $\S$ and Energy matrix $\L$:')
            disp('\[\S = \left\{\begin{array}{@{}r@{\;}c@{\;}l@{}}')
            disp('\L\,\dot{\x}&=&\A\,\x + \B\,\u\\')
            disp('\y &=& \C\,\x+ \D\,\u')
            disp('\end{array} \right.')
            disp(',\hspace{15mm} \L=')
            disp(Filtra_Str(latex(Equazioni_In.L)))
            disp('.\]')
            disp('Power matrix $\A$ and Input matrix $\B$: \[\A=')
            disp(Filtra_Str(latex(Equazioni_In.A)))
            disp(',\hspace{15mm} \B=')
            disp(Filtra_Str(latex(Equazioni_In.B)))
            disp('.\]')
            disp('Output matrix $\C$ and Input-output matrix $\D$: \[\C=')
            disp(Filtra_Str(latex(Equazioni_In.C)))
            disp(',\hspace{15mm} \D=')
            disp(Filtra_Str(latex(Equazioni_In.D)))
            disp('.\]')
            disp('State vector $\x$, Input vector $\u$ and Output vector $\y$: \[\x=')
            disp(Filtra_Str(latex(Equazioni_In.X)))
            disp(',\hspace{15mm} \u=')
            disp(Filtra_Str(latex(Equazioni_In.U)))
            disp(',\hspace{15mm} \y=')
            disp(Filtra_Str(latex(Equazioni_In.Y)))
            disp('.\]')
            disp(' ')
        case 'LAB'           % Le equazioni differenziali vengono scritte tutte assieme
            disp(' ')
            disp('State space equations:')                      
            disp('\[\begin{array}{@{}r@{\;}c@{\;}l@{}}')
            disp('\underbrace{')
            disp(Filtra_Str(latex(Equazioni_In.L)))
            disp('}_{\L}\dot{\x}')
            disp('&=& \underbrace{')
            disp(Filtra_Str(latex(Equazioni_In.A)))
            disp('}_{\A}\underbrace{')
            disp(Filtra_Str(latex(Equazioni_In.X)))
            disp('}_{\x}+\underbrace{')
            disp(Filtra_Str(latex(Equazioni_In.B)))
            disp('}_{\B}\u\\[5mm]\underbrace{')
            disp(Filtra_Str(latex(Equazioni_In.Y)))
            disp('}_{\y}&=&\underbrace{')
            disp(Filtra_Str(latex(Equazioni_In.C)))
            disp('}_{\C}\x+\underbrace{')
            disp(Filtra_Str(latex(Equazioni_In.D)))
            disp('}_{\D}\underbrace{')
            disp(Filtra_Str(latex(Equazioni_In.U)))
            disp('}_{\u} \end{array}\]')
            disp(' ')
        case 'MIN'           % Le equazioni differenziali vengono scritte in forma minima
            m=length(Equazioni_In.U);
            n=length(Equazioni_In.X);
            disp(' ')
            disp('State space equations:')                      
            disp('\[\begin{array}{@{}r@{\;}c@{\;}l@{}}')
            if n>0
                disp(Filtra_Str(latex(Equazioni_In.L)))
                disp('\dot{\x}&=&')
                disp(Filtra_Str(latex(Equazioni_In.A)))
                disp(Filtra_Str(latex(Equazioni_In.X)))
                disp('+')
                disp(Filtra_Str(latex(Equazioni_In.B)))
                disp(Filtra_Str(latex(Equazioni_In.U)))
                disp('\\[8mm]')
            end
            if m>0
                disp(Filtra_Str(latex(Equazioni_In.Y)))
                disp('&=&')
                if n>0
                    disp(Filtra_Str(latex(Equazioni_In.C)))
                    disp('\x+')
                end
                disp(Filtra_Str(latex(Equazioni_In.D)))
                if n==0
                    disp(Filtra_Str(latex(Equazioni_In.U)))
                else
                    disp('\u')
                end
                disp('\end{array}\]')
                disp(' ')
            end
    end
    if not(isempty(File))
        fclose(FID);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  mywrite(FID,Str)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fwrite(FID,Str);
fprintf(FID,'\n');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  mydisp(Str,FID)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if FID>0
    disp(Str)
    if ischar(Str)
        mywrite(FID,Str);
    else
        [Nr_Righe, Nr_Colonne]=size(Str);
        Str=char(Str);
        Ind_Open=strfind(Str,'[');
        Ind_Close=strfind(Str,']');
        Spazi=zeros(1,Nr_Colonne);
        if (Nr_Righe==1)&&(Nr_Colonne==1)
                mywrite(FID,['  ' Str ';']);
        else
            for jj=1:Nr_Righe
                Riga_jj=[',' Str(Ind_Open(jj+1)+1:Ind_Close(jj)-1) ','];
                Ind_Virg=strfind(Riga_jj,',');
                for ii=1:Nr_Colonne
                    Lung=Ind_Virg(ii+1)-Ind_Virg(ii);
                    if Spazi(ii)<Lung
                        Spazi(ii)=Lung;
                    end
                end
            end
            for jj=1:Nr_Righe
                Riga_ii='';
                Riga_jj=[',' Str(Ind_Open(jj+1)+1:Ind_Close(jj)-1) ','];
                Ind_Virg=strfind(Riga_jj,',');
                for ii=1:Nr_Colonne
                    Lung=Ind_Virg(ii+1)-Ind_Virg(ii);
                    Riga_ii=[Riga_ii blanks(Spazi(ii)-Lung) Riga_jj(Ind_Virg(ii)+1:Ind_Virg(ii+1))];
                end
                Riga_ii=Riga_ii(1:end-1);
                if jj==1
                    if Nr_Righe==1
                        Str_jj=[' [' Riga_ii ' ];'];
                    else
                        Str_jj=[' [' Riga_ii ' ;...'];
                    end
                elseif jj==Nr_Righe
                    Str_jj=['  ' Riga_ii '];'];
                else
                    Str_jj=['  ' Riga_ii ' ;...'];
                end
                mywrite(FID,Str_jj);
            end
        end
        fprintf(FID,'\n');
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Str = Filtra_Str(Str)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Str=strrep(Str,'\left(\begin{array}{} \end{array}\right)','');
Str=strrep(Str,'\left(','\left[');
Str=strrep(Str,'\right)','\right]');
Str=strrep(Str,'\mathrm','');
Str=strrep(Str,'\\','\\[2mm]');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%...%%%%%%%%%%   SHOW_SCHEMA_A_BLOCCHI_POG             %%%%%%%%%%%%%%%%%%%%
%...%%%%%%%%%%   SHOW_SCHEMA_A_BLOCCHI_POG             %%%%%%%%%%%%%%%%%%%%
%...%%%%%%%%%%   SHOW_SCHEMA_A_BLOCCHI_POG             %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Sistema = SHOW_SCHEMA_A_BLOCCHI_POG(Sistema)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp(' ')
Sistema.Old_Lista_Rami=Sistema.Lista_Rami;
Sistema.Old_Lista_Nodi=Sistema.Lista_Nodi;      % Si lavora su di una copia di Lista_Nodi
Lista_Rami=Sistema.Lista_Rami;
Sistema.Ultimo_Ramo=Sistema.Nr_dei_Rami;        % Puntatore all'ultimo ramo dello schema 
Ultimo_Ramo=Sistema.Ultimo_Ramo;                % Ultimo_Ramo -> variabile incrementale 
Partizione=Sistema.Partizione;                  % 
Show_Lista_Rami_SP=Sistema.Show_Lista_Rami_SP;
for ii=1:length(Partizione)
    %%%% Dalla partizione si tolgono i nodi del ramo "Input_POG_ii"
    Primo_Ramo=Ultimo_Ramo+1;                   % Puntatore al primo ramo della partizione
    Ramo_UNO=Partizione(ii).Ramo_UNO;
    Ramo_Start=Lista_Rami(Ramo_UNO);
    Nodi_da_Ridurre=setdiff(Partizione(ii).Nodi,[Ramo_Start.From Ramo_Start.To]);
    %%%% SVILUPPA IN SERIE E PARALLELO LA PARTIZIONE CORRENTE DELLO SCHEMA
    Sistema = SVILUPPA_SERIE_PARALLELO(Sistema,Nodi_da_Ridurre);
    %%%% SVILUPPA IN PARALLELO LA CONNESSIONE CON IL RAMO "Input_POG_ii"
    Nodi_da_Ridurre=Ramo_Start.From;
    Sistema = SVILUPPA_SERIE_PARALLELO(Sistema,Nodi_da_Ridurre);
    % La funzione SVILUPPA_SERIE_PARALLELO modifica le variabili
    % "Lista_Rami" e "Ultimo_Ramo". Queste due variabili vengono aggiornate:
    Lista_Rami=Sistema.Lista_Rami;                  
    Ultimo_Ramo=Sistema.Ultimo_Ramo;                
    % I Rami di inizio e di fine delle partizioni sono ora ti tipo 'SP' 
    Partizione(ii).Primo_Ramo=Primo_Ramo;
    Partizione(ii).Ultimo_Ramo=Ultimo_Ramo;
    %%%% VISUALIZZA I RAMI AGGIUNTI
    String_POG=['Input = ' num2str(Ramo_UNO) ' -> '];
%     SHOW_LISTA_RAMI_POG(Show_Lista_Rami_SP,Lista_Rami,Primo_Ramo,Ultimo_Ramo,String_POG,'Lista Rami Aggiunti:')
    %%%% RIDUCE I RAMI IN GRUPPI SERIE E PARALLELO
    Lista_Rami = RIDUCI_SERIE_PARALLELO(Lista_Rami,Ultimo_Ramo);
    % La funzione RIDUCI_SERIE_PARALLELO modifica la variabile "Lista_Rami"
    %%%% VISUALIZZA I RAMI RIDOTTI E NON COLLEGATI
    SHOW_LISTA_RAMI_POG(Show_Lista_Rami_SP,Lista_Rami,Primo_Ramo,Ultimo_Ramo,String_POG,'Lista Rami Ridotti ma NON Collegati:')
    Sistema.Lista_Rami=Lista_Rami;    
end
Sistema.Partizione=Partizione;                  % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% SI CREANO I COLLEGAMENTI TRA LE PARTIZIONI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii=1:length(Partizione)
    Primo_Ramo=Partizione(ii).Primo_Ramo;          
    Ultimo_Ramo=Partizione(ii).Ultimo_Ramo;
    if not(isempty(Partizione(ii).Links))
        Puntatori_a_Links_Forward=find(strcmp({Partizione(ii).Links.Forward},'Si'));   
        for jj=Puntatori_a_Links_Forward                        % Per tutti i link "Forward" ...
            Primo=Partizione(ii).Links(jj).Primo;               % Primo elemento del link "Forward" (Blocco di Connessione)
            Next_Partiz=Partizione(ii).Links(jj).Next_Partiz;   % Prossima partizione
            for Ramo_jj=Primo_Ramo:Ultimo_Ramo                  % Si cerca tra tutti i Rami "SP" della partizone
                Puntatore_a_Ramo_Primo= Lista_Rami(Ramo_jj).SP_Rami==Primo;         % ... quello che contiene il Primo elemento
                %%% Il Ramo Foglia "Primo" viene sostituito dal Ramo "SP" che inizia con il Blocco di Connessione 
                Lista_Rami(Ramo_jj).SP_Rami(Puntatore_a_Ramo_Primo)=Partizione(Next_Partiz).Ultimo_Ramo;
                %%% Ordinamento di SP_Rami che pone i Rami SP alla fine del vettore
                Lista_Rami(Ramo_jj).SP_Rami=sort(Lista_Rami(Ramo_jj).SP_Rami);      
                kk=find(Puntatore_a_Ramo_Primo==1,1);
                if not(isempty(kk))&&ismember(Lista_Rami(Primo).TR_o_GY,'TG')
                    %%% Il Ramo "SP" viene contrassegnato con il tipo 'G' o 'T' del Ramo Primo che � stato tolto
                    Lista_Rami(Ramo_jj).SP_di_tipo_TG=Lista_Rami(Primo).TR_o_GY;
                end
            end
        end
    end
    String_POG=['Input = ' num2str(Partizione(ii).Ramo_UNO) ' -> '];
    SHOW_LISTA_RAMI_POG(Show_Lista_Rami_SP,Lista_Rami,Primo_Ramo,Ultimo_Ramo,String_POG,'Lista Rami Ridotti e Collegati:')
end
%%%% MOSTRA LA STRUTTURA SERIE-PARALLELO
if strcmp(Show_Lista_Rami_SP,'Si')
    disp(' '); disp('Struttura Serie-Parallelo');
end
%%%% COPIA POG_SYS IN RAMI.POG
for ii=1:length(Lista_Rami)
    Lista_Rami(ii).POG=COPY_TO(Sistema.POG_SYS,Lista_Rami(ii).POG);
end
%%%%%%%%%%%%%%%%
for ii=Sistema.Input_POG
    Ind=NR_PARTIZIONE_CHE_CONTIENE_IL_RAMO(Partizione,ii);
    % L'ultimo ramo della partizione � il punto di partenza per la struttura serie/parallelo 
    Ramo_di_Partenza=Partizione(Ind).Ultimo_Ramo;
    Lista_Rami(1).SP_di_tipo_TG='';
    Lista_Rami = CALCOLA_EFFORT_E_FLOW(Lista_Rami,Ramo_di_Partenza);
    SHOW_STRUTTURA_SERIE_PARALLELO(Show_Lista_Rami_SP,Lista_Rami,Ramo_di_Partenza)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CALCOLA LE STRINGHE SINTETICHE CHE DESCRIVONO LA STRUTTURA SERIE/PARALLELO
    [Str_Num,Str_EoF]=SHORT_SERIE_PARALLELO(Lista_Rami,Ramo_di_Partenza);
    if strcmp(Show_Lista_Rami_SP,'Si')
        disp(Str_Num)
        disp(Str_EoF)
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % OGNI RAMO 'SP' EREDITA LA STRUTURA 'POG' DEL SUO PRIMO ELEMENTO FOGLIA
%     Lista_Rami=POG_FROM_FOGLIA_TO_SP(Lista_Rami,Ramo_di_Partenza);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Lista_Rami(Ramo_di_Partenza).POG.X1=-11*(Ind-1)*1i+eps*1i;
    Lista_Rami(Ramo_di_Partenza).POG.X2=-11*(Ind-1)*1i;
    Lista_Rami(Ramo_di_Partenza).POG.X3=-11*(Ind-1)*1i;
    Lista_Rami(Ramo_di_Partenza).POG.pog_Vai_a_Destra='Si';
    Lista_Rami(Ramo_di_Partenza).POG.pog_Effort_Su=Lista_Rami(ii).POG.pog_Effort_Su;
    Lista_Rami(Ramo_di_Partenza).POG.Str_Type='000';
    Lista_Rami(Ramo_di_Partenza).POG.Draw1={};
    Lista_Rami(Ramo_di_Partenza).POG.Draw2={};
    Lista_Rami(Ramo_di_Partenza).Out='0';
%     Lista_Rami(Ramo_di_Partenza).POG=COPY_TO(Sistema.POG_SYS,Lista_Rami(Ramo_di_Partenza).POG);
    Lista_Rami = CALCOLA_STR_TYPE(Lista_Rami,Ramo_di_Partenza);
    Lista_Rami = CALCOLA_DIMENSIONE_BLOCCI(Lista_Rami,Ramo_di_Partenza);
    Lista_Rami(Ramo_di_Partenza).POG.Altezza_2=Lista_Rami(Ramo_di_Partenza).POG.Altezza;
    Lista_Rami = CALCOLA_POSIZIONE_BLOCCI(Lista_Rami,Ramo_di_Partenza);    
end
Sistema.Lista_Rami=Lista_Rami;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% MOSTRA LA STRUTTURA SERIE-PARALLELO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if Sistema.Grafico.Nr_Figura==0
    figure(Sistema.Nr_Schema+100)
else
    figure(Sistema.Grafico.Nr_Figura+100)
end
clf; hold on; axis equal;  axis off; zoom on
for ii=Sistema.Input_POG
    Ind=NR_PARTIZIONE_CHE_CONTIENE_IL_RAMO(Partizione,ii);
    Ramo_di_Partenza=Partizione(Ind).Ultimo_Ramo;
    SHOW_RAMI_POG(Show_Lista_Rami_SP,Lista_Rami,Ramo_di_Partenza);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% STAMPA IL GRAFICO DELLO SCHEMA POG NEL FORMATO RICHIESTO  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Sistema.POG_SYS.pog_Print_POG,'Si')
    PRINT_FIGURA([Sistema.Grafico.Dir_out Sistema.Grafico.Nome_del_grafico],Sistema.POG_SYS.pog_Graphic_Type,'_POG')
end
Sistema.Schema_POG_Generato='Si';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     Sistema=SVILUPPA_SERIE_PARALLELO(Sistema,Nodi_da_Ridurre)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Crea una copia di Lista_Rami, Lista_Nodi e Ultimo_Ramo
Lista_Rami=Sistema.Lista_Rami;
Lista_Nodi=Sistema.Lista_Nodi;
Ultimo_Ramo=Sistema.Ultimo_Ramo;                % Puntatore all'ultimo ramo
%%%% Riduzione serie/parallelo dello schema 
Continua_a_Ridurre='Si';
while strcmp(Continua_a_Ridurre,'Si')
    Continua_a_Ridurre='No';
    for Nodo_ii=Nodi_da_Ridurre             % Si cicla sui nodi da ridurre
        Next_Nodi=Lista_Nodi(Nodo_ii).Next_Nodi;
        Next_Rami=Lista_Nodi(Nodo_ii).Next_Rami;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% RIDUZIONE DEI RAMI IN PARALLELO
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Range=1;
        for ii=2:length(Next_Nodi)              % Solo se length(Next_Nodi)>=2
            if Next_Nodi(ii)==Next_Nodi(ii-1)   % I due Next_Nodi sono uguali
                Ultimo_Ramo=Ultimo_Ramo+1;      % Si aggiunge un ramo  'Parallelo'
                % Si definiscono i parametri del nuovo Ramo
                Lista_Rami(Ultimo_Ramo).SP='Parallelo';         % E' un ramo di tipo 'Parallelo'
                Lista_Rami(Ultimo_Ramo).Nome_Ramo='SP';         % E' un ramo aggiuntivo con sigla 'SP'
                Lista_Rami(Ultimo_Ramo).SP_Rami=sort(abs(Next_Rami([ii-1 ii])));    % Rami in parallelo
                Lista_Rami(Ultimo_Ramo).From=Nodo_ii;           % Nodo From
                Lista_Rami(Ultimo_Ramo).To=Next_Nodi(ii);       % Nodo To
                Lista_Rami(Ultimo_Ramo).SP_Out={};              % 
                Lista_Rami(Ultimo_Ramo).TR_o_GY='';             %                 
                %%% Il precedente link di ramo del nodo coniugato punta al Nuovo_Ramo
                Ind=Lista_Nodi(Next_Nodi(ii-1)).Next_Rami==-Next_Rami(ii-1);
                Lista_Nodi(Next_Nodi(ii-1)).Next_Rami(Ind)=-Ultimo_Ramo;
                %%% I correnti link di ramo e di nodo del nodo coniugato vengono tolti
                Ind=find(Lista_Nodi(Next_Nodi(ii)).Next_Rami~=-Next_Rami(ii));
                Lista_Nodi(Next_Nodi(ii)).Next_Rami=Lista_Nodi(Next_Nodi(ii)).Next_Rami(Ind);
                Lista_Nodi(Next_Nodi(ii)).Next_Nodi=Lista_Nodi(Next_Nodi(ii)).Next_Nodi(Ind);
                %%% I link di nodo e i link di ramo del nodo coniugato vengono ordinati
                [Lista_Nodi(Next_Nodi(ii)).Next_Nodi, Ind]=sort(Lista_Nodi(Next_Nodi(ii)).Next_Nodi);
                Lista_Nodi(Next_Nodi(ii)).Next_Rami=Lista_Nodi(Next_Nodi(ii)).Next_Rami(Ind);
                %%% Il precedente link di ramo del nodo corrente punta al Nuovo_Ramo
                Next_Rami([ii-1 ii])=Ultimo_Ramo;
                %%%
                Continua_a_Ridurre='Si';
                Range(end)=Range(end)+1;
            else
                Range=[Range ii];
            end
        end
        Next_Nodi=Next_Nodi(Range);
        Next_Rami=Next_Rami(Range);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% RIDUZIONE DEI RAMI IN SERIE
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if length(Next_Nodi)==2
            Ultimo_Ramo=Ultimo_Ramo+1;          % Si aggiunge un ramo 'Serie'
            Lista_Rami(Ultimo_Ramo).SP='Serie';
            Lista_Rami(Ultimo_Ramo).Nome_Ramo='SP';
            Lista_Rami(Ultimo_Ramo).SP_Rami=sort(abs(Next_Rami.*[-1 1]));
            Lista_Rami(Ultimo_Ramo).From=Next_Nodi(1);
            Lista_Rami(Ultimo_Ramo).To=Next_Nodi(2);
            Lista_Rami(Ultimo_Ramo).SP_Out={};              %
            Lista_Rami(Ultimo_Ramo).TR_o_GY='';             %
            %%% Il link di ramo del primo nodo coniugato punta a Nuovo_Ramo
            Ind=Lista_Nodi(Next_Nodi(1)).Next_Rami==-Next_Rami(1);
            Lista_Nodi(Next_Nodi(1)).Next_Rami(Ind)=Ultimo_Ramo;
            %%% Il link di nodo del primo nodo coniugato punta al secondo nodo coniugato
            Lista_Nodi(Next_Nodi(1)).Next_Nodi(Ind)=Next_Nodi(2);
            %%% I link di nodo  e i link di ramo del primo nodo coniugato vengono ordinati
            [Lista_Nodi(Next_Nodi(1)).Next_Nodi, Ind]=sort(Lista_Nodi(Next_Nodi(1)).Next_Nodi);
            Lista_Nodi(Next_Nodi(1)).Next_Rami=Lista_Nodi(Next_Nodi(1)).Next_Rami(Ind);
            %%% Il link di ramo del secondo nodo coniugato punta a -Nuovo_Ramo
            Ind=Lista_Nodi(Next_Nodi(2)).Next_Rami==-Next_Rami(2);
            Lista_Nodi(Next_Nodi(2)).Next_Rami(Ind)=-Ultimo_Ramo;
            %%% Il link di nodo del secondo nodo coniugato punta al primo nodo coniugato
            Lista_Nodi(Next_Nodi(2)).Next_Nodi(Ind)=Next_Nodi(1);
            %%% I link di nodo  e i link di ramo del secondo nodo coniugato vengono ordinati
            [Lista_Nodi(Next_Nodi(2)).Next_Nodi, Ind]=sort(Lista_Nodi(Next_Nodi(2)).Next_Nodi);
            Lista_Nodi(Next_Nodi(2)).Next_Rami=Lista_Nodi(Next_Nodi(2)).Next_Rami(Ind);
            %%%
            Next_Nodi=[];
            Next_Rami=[];
            Nodi_da_Ridurre=setdiff(Nodi_da_Ridurre,Nodo_ii);
            Continua_a_Ridurre='Si';
        end
        Lista_Nodi(Nodo_ii).Next_Nodi=Next_Nodi;
        Lista_Nodi(Nodo_ii).Next_Rami=Next_Rami;                
    end
end
if length(Nodi_da_Ridurre)>1
    beep;
    disp('Errore: schema non ridotto ai minimi termini')
    disp(['Nodi da ridurre: ' num2str(Nodi_da_Ridurre)])
    Sistema.Schema_Ridotto='No';
else    
    Sistema.Schema_Ridotto='Si';
end
Sistema.Lista_Rami=Lista_Rami;
Sistema.Lista_Nodi=Lista_Nodi;          % Si lavora su di una copia di Lista_Nodi
Sistema.Ultimo_Ramo=Ultimo_Ramo;        % Puntatore all'ultimo ramo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Lista_Rami = RIDUCI_SERIE_PARALLELO(Lista_Rami,Ramo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isfield(Lista_Rami(Ramo),'SP_Rami')
    SP_Rami=Lista_Rami(Ramo).SP_Rami;
    for Ramo_ii=Lista_Rami(Ramo).SP_Rami
        Lista_Rami=RIDUCI_SERIE_PARALLELO(Lista_Rami,abs(Ramo_ii));
        if strcmp(Lista_Rami(Ramo).SP,Lista_Rami(abs(Ramo_ii)).SP)
            SP_Rami=[setdiff(SP_Rami,Ramo_ii) sign(Ramo_ii)*Lista_Rami(abs(Ramo_ii)).SP_Rami];
            Lista_Rami(abs(Ramo_ii)).SP_Rami=[];
        end
    end
    Lista_Rami(Ramo).SP_Rami=sort(SP_Rami);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function   SHOW_LISTA_RAMI_POG(Show_Lista_Rami_SP,Lista_Rami,Primo_Ramo,Ultimo_Ramo,String_POG,Titolo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Show_Lista_Rami_SP,'Si')
    Space_POG=blanks(length(String_POG));
    disp(' '); disp([String_POG Titolo]);
    for ii=Primo_Ramo:Ultimo_Ramo
        Ramo_ii=Lista_Rami(ii);
        disp([Space_POG num2str(ii) ' = ' Ramo_ii.SP ' = [' num2str(Ramo_ii.From) ', ' num2str(Ramo_ii.To) '] -> [' num2str(Ramo_ii.SP_Rami) ']'])
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function    Lista_Rami = CALCOLA_EFFORT_E_FLOW(Lista_Rami,ii)  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ramo_ii=Lista_Rami(ii);
Ramo_ii.SP_Out={};
for jj=1:length(Ramo_ii.SP_Rami)
    Ramo_jj=Ramo_ii.SP_Rami(jj);
    if not(strcmp(Lista_Rami(Ramo_jj).SP,'Foglia'))
        Lista_Rami = CALCOLA_EFFORT_E_FLOW(Lista_Rami,Ramo_jj);
    end
    Ramo_ii.SP_Out=[ Ramo_ii.SP_Out Lista_Rami(Ramo_jj).Out];
end
if ismember(Ramo_ii.SP_di_tipo_TG,'TG')
    Out_Secondo=Lista_Rami(Ramo_ii.SP_Rami(end)).SP_Out{1};
    switch Ramo_ii.SP_di_tipo_TG
        case 'G'
            switch Out_Secondo
                case 'Flow'
                    Ramo_ii.SP_Out{end}='Flow';
                case 'Effort'
                    Ramo_ii.SP_Out{end}='Effort';
            end
        case 'T'
            switch Out_Secondo
                case 'Flow'
                    Ramo_ii.SP_Out{end}='Effort';
                case 'Effort'
                    Ramo_ii.SP_Out{end}='Flow';
            end
    end
end
switch Ramo_ii.SP
    case 'Serie'
        Ramo_ii.Out='Flow';
        if strcmp(Ramo_ii.SP_Out,'Effort')      % Se tutti gli elementi sono di tipo 'Effort' ...
            Ramo_ii.Out='Effort';
        end
    case 'Parallelo'
        Ramo_ii.Out='Effort';
        if strcmp(Ramo_ii.SP_Out,'Flow')        % Se tutti gli elementi sono di tipo 'Flow' ...
            Ramo_ii.Out='Flow';
        end
end
Lista_Rami(ii)=Ramo_ii;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SHOW_STRUTTURA_SERIE_PARALLELO(Show_Lista_Rami_SP,Lista_Rami,ii)  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Show_Lista_Rami_SP,'Si')
    Ramo_ii=Lista_Rami(ii);
    % Gli elementi in parallelo racchiusi tra parentesi quadre: '[ ... ]'
    Str_1=[num2str(ii) ' = ' Ramo_ii.SP ' = [' num2str(Ramo_ii.From) ', ' num2str(Ramo_ii.To) '] -> ['];
    Str_2=[blanks(length(Str_1)-2) ' ['];
    Str_4=[];
    for ii=1:length(Ramo_ii.SP_Rami)
        jj=abs(Ramo_ii.SP_Rami(ii));
        Str_4=[ Str_4  num2str(jj) Lista_Rami(jj).TR_o_GY '  '];
    end
    Str_4(end)=']';
    % Gli elementi in serie racchiusi tra parentesi tonde: '( ... )'
    if strcmp(Ramo_ii.SP,'Serie')
        Str_1(end)='(';
        Str_2(end)='(';
        Str_4(end)=')';
    end
    Ind=find(Str_4==' ');                   % Ind: posizine degli spazi in Str_4
    Pnt=find(diff(Ind)==1)+1;               % Pnt: posizine degli spazi in Str_4 preceduti da spazi
    Ind=Ind(setdiff(1:length(Ind),Pnt));    % Ind: posizine degli spazi in Str_4 preceduti da un carattere
    Str_4=[' ' Str_4];
    Str_3=Str_4;
    for ii=1:length(Ind)
        E_o_F=Ramo_ii.SP_Out{ii}(1);
        Str_3(Ind(ii))=E_o_F;
        Str_3(Ind(ii)-1)=' ';
        if (Ind(ii)-2)>0
            Str_3(Ind(ii)-2)=' ';
        end
    end
    disp([Str_1 Str_4 ])
    disp([Str_2 Str_3 ])
    for jj=abs(Ramo_ii.SP_Rami)
        if not(strcmp(Lista_Rami(jj).SP,'Foglia'))
            SHOW_STRUTTURA_SERIE_PARALLELO(Show_Lista_Rami_SP,Lista_Rami,jj)
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Str_Num,Str_EoF]=SHORT_SERIE_PARALLELO(Lista_Rami,ii)  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCOLA LE STRINGHE SINTETICHE CHE DESCRIVONO LA STRUTTURA SERIE/PARALLELO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ramo_ii=Lista_Rami(ii);
% Gli elementi in parallelo racchiusi tra parentesi quadre: '[ ... ]' 
Str_3='[';
Str_4='[';
for ii=1:length(Ramo_ii.SP_Rami)
    jj=abs(Ramo_ii.SP_Rami(ii));
    Str_Num='';
    Str_EoF='';
    if not(strcmp(Lista_Rami(jj).SP,'Foglia'))
        [Str_Num,Str_EoF]=SHORT_SERIE_PARALLELO(Lista_Rami,jj);
    end
    Str_5 = [num2str(jj) Lista_Rami(jj).TR_o_GY];
    Str_4=[ Str_4 Str_5 Str_Num ' '];
    Str_6 = Str_5;
    Str_6(:) = ' ';
    Str_6(end) = Ramo_ii.SP_Out{ii}(1);    
    Str_3=[ Str_3 Str_6 Str_EoF ' '];
end
Str_4(end)=']';
Str_3(end)=']';
% Gli elementi in serie racchiusi tra parentesi tonde: '( ... )' 
if strcmp(Ramo_ii.SP,'Serie')
    Str_4(1)='(';
    Str_4(end)=')';
    Str_3(1)='(';
    Str_3(end)=')';
end
Str_Num=Str_4;
Str_EoF=Str_3;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     Lista_Rami = CALCOLA_STR_TYPE(Lista_Rami,ii)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ramo_ii=Lista_Rami(ii);                 % Il Ramo_ii di partenza e' sempre di tipo SP
POG_ii=Ramo_ii.POG;                 
E_o_F=Ramo_ii.Out(1);
Str = VALORE_CONIUGATO(E_o_F,'E','F');
for jj=1:length(Ramo_ii.SP_Rami) 
    Str=[Str Ramo_ii.SP_Out{jj}(1)];
end
Str=[Str '0'];                          % Str indica la sequenza di "E" e "F" che caratterizza la sequenza corrente di rami
for jj=1:length(Ramo_ii.SP_Rami)        % jj cicla in modo inverso su tutti i rami contenuti in "Ramo_ii.SP_Rami"
    Pnt_Ramo_jj=Ramo_ii.SP_Rami(jj);    % Pnt_Ramo_jj e' il puntatore al jj-esimo ramo in "Ramo_ii.SP_Rami" 
    Ramo_jj=Lista_Rami(Pnt_Ramo_jj);    % Ramo_jj contiene tutti i parametri del jj-esimo ramo 
    POG_jj=Ramo_jj.POG;                 % POG_jj contiene tutti i parametri POG di Ramo_jj
    ABC=Str(jj:jj+2);                   % Stringa che caratterizza il blocco
    switch ABC
        case 'EEE'          % Questo caso non esiste
            if isempty(strfind(Str(1:jj),'F'))
                ABC='EEF';
            else 
                ABC='FEE';
            end
        case 'FFF'          % Questo caso non esiste
            if isempty(strfind(Str(1:jj),'E'))
                ABC='FFE';
            else 
                ABC='EFF';
            end
    end
    POG_jj.Str_Type=ABC;                 % Si assegna una stringa ABC ad ogni Ramo (anche SP)
    POG_jj.pog_Vai_a_Destra=POG_ii.pog_Vai_a_Destra;    
    if jj==1
        POG_jj.pog_Effort_Su=POG_ii.pog_Effort_Su;
    else
        POG_jj.pog_Effort_Su=Lista_Rami(Ramo_ii.SP_Rami(jj-1)).POG.pog_Effort_Su;
    end
    if POG_jj.Str_Type(1)=='0'
        POG_jj.pog_Vai_a_Destra=VALORE_CONIUGATO(POG_jj.pog_Vai_a_Destra,'Si','No');
    end
    if strcmp(Ramo_jj.TR_o_GY,'G')
        POG_jj.pog_Effort_Su=VALORE_CONIUGATO(POG_jj.pog_Effort_Su,'Si','No');
    end
    if not(strcmp(Ramo_jj.SP,'Foglia'))
        Ramo_jj.POG=POG_jj;
        Lista_Rami(Pnt_Ramo_jj)=Ramo_jj;        
        Lista_Rami = CALCOLA_STR_TYPE(Lista_Rami,Pnt_Ramo_jj);
        Ramo_jj=Lista_Rami(Pnt_Ramo_jj);
        POG_jj=Ramo_jj.POG;
    end
    % Visualizza la stringa Str_Type
%     disp([num2str(Pnt_Ramo_jj) ' ' POG_jj.Str_Type ' Esu=' POG_jj.pog_Effort_Su ' Dst=' POG_jj.pog_Vai_a_Destra ' ' Lista_Rami(Pnt_Ramo_jj).TR_o_GY])
    Ramo_jj.POG=POG_jj;
    Lista_Rami(Pnt_Ramo_jj)=Ramo_jj;
end
Lista_Rami(ii)=Ramo_ii;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     Str = VALORE_CONIUGATO(Str,A,B)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch Str
    case A
        Str=B;
    case B
        Str=A;        
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     Lista_Rami = CALCOLA_DIMENSIONE_BLOCCI(Lista_Rami,ii)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ramo_ii=Lista_Rami(ii);             % Ramo_ii e' sempre di tipo SP
ii_Altezza=0;
ii_Lx_Dst=0;
Nr_SP_Rami=length(Ramo_ii.SP_Rami);
for jj=Nr_SP_Rami:-1:1     % jj cicla in modo inverso su tutti i rami contenuti in "Ramo_ii.SP_Rami"
    Pnt_Ramo_jj=Ramo_ii.SP_Rami(jj);    % Pnt_Ramo_jj e' il puntatore al jj-esimo ramo in "Ramo_ii.SP_Rami" 
    Ramo_jj=Lista_Rami(Pnt_Ramo_jj);    % Ramo_jj contiene tutti i parametri del jj-esimo ramo 
    POG_jj=Ramo_jj.POG;                 % POG_jj contiene tutti i parametri POG di Ramo_jj
    % Si copia in POG un paio di variabili di Ramo
    POG_jj.Nome_Ramo=Ramo_jj.Nome_Ramo; % Si copia Nome_Ramo in POG
    POG_jj.TR_o_GY=Ramo_jj.TR_o_GY;     % Si copia TR_o_GY in POG
    if not(strcmp(Ramo_jj.SP,'Foglia'))
        Ramo_jj.POG=POG_jj;
%         Ramo_jj.POG=COPY_TO(Ramo_ii.POG,Ramo_jj.POG);       % Trasferisce (in aggiunta) struttura POG da rami SP a rami SP.
        Lista_Rami(Pnt_Ramo_jj)=Ramo_jj;        
        Lista_Rami = CALCOLA_DIMENSIONE_BLOCCI(Lista_Rami,Pnt_Ramo_jj);
        Ramo_jj=Lista_Rami(Pnt_Ramo_jj);
        POG_jj=Ramo_jj.POG;
        if jj<Nr_SP_Rami
            POG_jj.Altezza=POG_jj.Altezza+2*imag(POG_jj.X1_Shift);
            POG_jj.Lx_Dst=POG_jj.Lx_Dst+POG_jj.Lx_Snt+1.5*real(Ramo_ii.POG.X1_Shift);
        end
    else
        switch POG_jj.Str_Type
            case {'EF0','FE0','FF0','EE0','0FE','0EF','0FF','0EE'}
                if POG_jj.Nome_Ramo(2)=='U'
                    POG_jj.pog_Block_S_dx=0;
                    POG_jj.pog_Block_M_dx=0;
                end
        end
        POG_jj.Altezza=2*POG_jj.pog_From_S_to_M_dy+POG_jj.pog_Block_M_dy+0.5;
        POG_jj.Lx_Dst=POG_jj.pog_Space_dx;
        POG_jj.Lx_Snt=POG_jj.pog_Space_dx;
        POG_jj.MxM='No';        
        if strcmp(Ramo_jj.Tipo_di_Ramo,'Dinamico')
            POG_jj.MxM='Si';
            POG_jj.Altezza=POG_jj.Altezza+POG_jj.pog_From_S_to_M_dy+POG_jj.pog_Block_S_dy;
            if POG_jj.pog_Block_S_dx>POG_jj.pog_Block_M_dx
                POG_jj.Lx_Dst=POG_jj.Lx_Dst+POG_jj.pog_Block_S_dx/2;
                POG_jj.Lx_Snt=POG_jj.Lx_Snt+POG_jj.pog_Block_S_dx/2;
            else
                POG_jj.Lx_Dst=POG_jj.Lx_Dst+POG_jj.pog_Block_M_dx/2;
                POG_jj.Lx_Snt=POG_jj.Lx_Snt+POG_jj.pog_Block_M_dx/2;
            end
        else
            POG_jj.Lx_Dst=POG_jj.Lx_Dst+POG_jj.pog_Block_M_dx/2;
            POG_jj.Lx_Snt=POG_jj.Lx_Snt+POG_jj.pog_Block_M_dx/2;
        end
    end
    Ramo_jj.POG=POG_jj;
    Lista_Rami(Pnt_Ramo_jj)=Ramo_jj;
    ii_Lx_Dst=ii_Lx_Dst+POG_jj.Lx_Snt+POG_jj.Lx_Dst;
    if POG_jj.Altezza>ii_Altezza
        ii_Altezza=POG_jj.Altezza;
    end
end
for jj=1:length(Ramo_ii.SP_Rami)     
    Lista_Rami(Ramo_ii.SP_Rami(jj)).POG.Altezza=ii_Altezza;
    Str=[' ' num2str(Ramo_ii.SP_Rami(jj)) ' '];
    Str1=[num2str(Lista_Rami(Ramo_ii.SP_Rami(jj)).POG.Lx_Snt) '   '];
    Str2=[num2str(Lista_Rami(Ramo_ii.SP_Rami(jj)).POG.Lx_Dst) '   '];
    Str3=[num2str(Lista_Rami(Ramo_ii.SP_Rami(jj)).POG.Altezza) '   '];
    % Visualizza le dimensioni dei blochi 
    %    disp([ Str(1:3) ' Snt= ' Str1(1:4) ' Dst= ' Str2(1:4) ' Alt= ' Str3(1:4)])
end
Ramo_ii.POG.Altezza=ii_Altezza;
Ramo_ii.POG.Lx_Snt=Lista_Rami(Ramo_ii.SP_Rami(1)).POG.Lx_Snt;    
Ramo_ii.POG.Lx_Dst=ii_Lx_Dst-Ramo_ii.POG.Lx_Snt;
Lista_Rami(ii)=Ramo_ii;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     Lista_Rami = CALCOLA_POSIZIONE_BLOCCI(Lista_Rami,ii)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ramo_ii=Lista_Rami(ii);                 % Ramo_ii e' sempre di tipo SP
Nr_SP_Rami=length(Ramo_ii.SP_Rami);
Nero=0; 
%%% Se il ramo SP � di tipo Split, tutti ti blocchi futuri vengono spostati
%%% e si inseriscono dei puntini all'inizio
if strfind(Ramo_ii.POG.Split_POG,'-1')      % Mostra quali sono i blocchi "Split"
    disp(['Split block: ' num2str(ii) ' -> ' num2str(Ramo_ii.SP_Rami(1))])
end
if strfind(Ramo_ii.POG.Split_POG,num2str(ii))   % Se il blocco � di tipo "Split"
    Sposta=-real(Ramo_ii.POG.X1)-(Ramo_ii.POG.Altezza+Ramo_ii.POG.Split_POG_Ver_Dx)*1i;
    Ramo_ii.POG.Draw1=[Ramo_ii.POG.Draw1,...                    % In un blocco Split ...
        'Dots_dst'  ,-0.5-0.5*Ramo_ii.POG.Altezza*1i, Nero];    %  ... si aggiungono i puntini a destra
    Ramo_ii.POG.X1=Ramo_ii.POG.X1+Sposta;
    Ramo_ii.POG.X2=Ramo_ii.POG.X2+Sposta;
    Ramo_ii.POG.X3=Ramo_ii.POG.X3+Sposta;
end
for jj=1:Nr_SP_Rami                     % jj cicla in modo inverso su tutti i rami contenuti in "Ramo_ii.SP_Rami"
    Pnt_Ramo_jj=Ramo_ii.SP_Rami(jj);    % Pnt_Ramo_jj e' il puntatore al jj-esimo ramo in "Ramo_ii.SP_Rami" 
    Ramo_jj=Lista_Rami(Pnt_Ramo_jj);    % Ramo_jj contiene tutti i parametri del jj-esimo ramo 
    POG_jj=Ramo_jj.POG;                 % POG_jj contiene tutti i parametri POG di Ramo_jj
    % L'altezza del Ramo SP corrente viene assegnata anche a tutti i Rami_SP
    POG_jj.Altezza=Ramo_ii.POG.Altezza_2;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Definizione del punto di partenza X1
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if jj==1                                
        if Ramo_ii.POG.X2==Ramo_ii.POG.X3   % X2=X3 solo per l'ultimo blocco SP 
            POG_jj.X1=Ramo_ii.POG.X3;   
        else
            POG_jj.X1=Ramo_ii.POG.X2+0.5*1i+conj(Ramo_ii.POG.X1_Shift);
        end
    else
        POG_jj_m1=Lista_Rami(Ramo_ii.SP_Rami(jj-1)).POG;
        if strcmp(POG_jj_m1.pog_Vai_a_Destra,POG_jj.pog_Vai_a_Destra)
            POG_jj.X1=POG_jj_m1.X3;
        else
            POG_jj.X1=POG_jj_m1.X1;
        end
    end
    if jj<Nr_SP_Rami                        % Per tutti i rami tranne l'ultimo: Draw1={...}, X2=... e X3=...
        POG_jj = SHAPE_DRAW_1(POG_jj);      % ... si calcola la parte "esterna" del blocco   
    else                                    
        if strcmp(POG_jj.Nome_Ramo,'SP')    % Se l'ultimo ramo � di tipo 'SP': ...
            POG_jj.Draw1={};                % ... Draw1={}, 
            POG_jj.X2=POG_jj.X1;            % ... X2=X1 e X3=X1.
            POG_jj.X3=POG_jj.X1;
        else                                % ... 2) se l'ultimo ramo � di tipo 'Foglia: 'Draw1={...}, X2=... e X3=...
            POG_jj=SHAPE_DRAW_1(POG_jj);    % ... si calcola la parte "esterna" del blocco
        end
    end
    if strcmp(Ramo_jj.SP,'Foglia')          % Per i rami di tipo 'Foglia: 
        POG_jj=SHAPE_DRAW_2(POG_jj);        % ... disegna la parte "interna" del blocco
    else
        if jj<Nr_SP_Rami                    % Per i rami di tipo 'SP' non ultimi del gruppo ...
            POG_jj.Altezza_2=POG_jj.Altezza-2*imag(POG_jj.X1_Shift);
        else                                % Se il ramo di tipo 'SP' � l'ultimo del gruppo ...
            POG_jj.Altezza_2=POG_jj.Altezza;
        end
        POG_jj.Draw2={};                    % Tutti i rami di tipo 'SP' non hanno la parte "interna"
        Ramo_jj.POG=POG_jj;
        Lista_Rami(Pnt_Ramo_jj)=Ramo_jj;           
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% Se il ramo "SP" � di tipo Split, nel blocco antecendente ...
        %%%% ... si inserisce un tratteggio e dei puntini 
        if strfind(Ramo_jj.POG.Split_POG,num2str(Pnt_Ramo_jj))  % Se il blocco attuale � di tipo Split ...
            POG_jj_m1=Lista_Rami(Ramo_ii.SP_Rami(jj-1)).POG;    % Si accede al blocco antecendente 
            Sposta_X=real(Ramo_jj.POG.X1);                      % Si calcola Sposta_X
            Dx=POG_jj_m1.Lx_Dst+POG_jj_m1.Lx_Snt;               % Largezza dell blocco POG_jj_m1
            Altezza=POG_jj_m1.Altezza;                          % Altezza dell blocco POG_jj_m1
            Vert_Dx=Ramo_ii.POG.Split_POG_Ver_Dx;               % Distanza verticale tra i due split
            Sopra_Out = [Dx+0.0*1i Dx+3+0.0*1i Dx+3-(Altezza+Vert_Dx/2+0.5)*1i ...
                Dx-2-Sposta_X-(Altezza+Vert_Dx/2+0.5)*1i Dx-2-Sposta_X-(Altezza+Vert_Dx)*1i ...
                Dx-Sposta_X-(Altezza+Vert_Dx)*1i ];             % Linea che esce da sopra
            Sopra_In = fliplr(Sopra_Out);                       % Linea che entra da sopra
            Sotto_Out = [Dx-(Altezza)*1i Dx+2-(Altezza)*1i Dx+2-(Altezza+Vert_Dx/2-0.5)*1i ...
                Dx-3-Sposta_X-(Altezza+Vert_Dx/2-0.5)*1i Dx-3-Sposta_X-(2*Altezza+Vert_Dx)*1i ...
                Dx-Sposta_X-(2*Altezza+Vert_Dx)*1i ];           % Linea che esce da sotto
            Sotto_In = fliplr(Sotto_Out);                       % Linea che entra da sotto
            POG_jj_m1.Draw1=[POG_jj_m1.Draw1,...
                'tratteggio', [Dx+0.5*1i Dx-(Altezza+0.5)*1i], Nero,... % Aggiunge tratteggio ...
                'Dots_snt'  ,Dx+0.5-0.5*Altezza*1i, Nero];      % ... e puntini nel blocco POG_jj_m1
            Effort_Su = POG_jj_m1.pog_Effort_Su;                % Effort_Su del blocco POG_jj_m1
            TR_o_GY = POG_jj_m1.TR_o_GY;                        % TR_o_GY del blocco POG_jj_m1
            ABC = POG_jj_m1.Str_Type;                           % ABC del blocco POG_jj_m1
            if (strcmp(ABC,'EEF')&&strcmp(Effort_Su,'Si'))||...
                    (strcmp(ABC,'FEF')&&strcmp(Effort_Su,'Si'))||...
                    (strcmp(ABC,'EFF')&&strcmp(Effort_Su,'Si'))||...
                    (strcmp(ABC,'EFE')&&strcmp(Effort_Su,'No'))||...
                    (strcmp(ABC,'FEE')&&strcmp(Effort_Su,'No'))||...
                    (strcmp(ABC,'FFE')&&strcmp(Effort_Su,'No'))||...
                    (strcmp(ABC,'FEF')&&strcmp(Effort_Su,'Si')&&strcmp(TR_o_GY,'T'))||...
                    (strcmp(ABC,'EEF')&&strcmp(Effort_Su,'Si')&&strcmp(TR_o_GY,'T'))||...
                    (strcmp(ABC,'FEF')&&strcmp(Effort_Su,'Si')&&strcmp(TR_o_GY,'G'))||...
                    (strcmp(ABC,'EEF')&&strcmp(Effort_Su,'Si')&&strcmp(TR_o_GY,'G'))
                POG_jj_m1.Draw1=[POG_jj_m1.Draw1,'Split_Sopra_Out', Sopra_Out, Nero];
                POG_jj_m1.Draw1=[POG_jj_m1.Draw1,'Split_Sotto_In', Sotto_In, Nero];
            else
                POG_jj_m1.Draw1=[POG_jj_m1.Draw1,'Split_Sopra_In', Sopra_In, Nero];
                POG_jj_m1.Draw1=[POG_jj_m1.Draw1,'Split_Sotto_Out', Sotto_Out, Nero];
            end            
            Lista_Rami(Ramo_ii.SP_Rami(jj-1)).POG=POG_jj_m1;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Lista_Rami = CALCOLA_POSIZIONE_BLOCCI(Lista_Rami,Pnt_Ramo_jj);
        Ramo_jj=Lista_Rami(Pnt_Ramo_jj);
        POG_jj=Ramo_jj.POG;
    end
    POG_jj = SWAP_POG(POG_jj);          % Se necessario inverte la direzione "su/giu" e "dst/snt" dei vettore 
    Ramo_jj.POG = POG_jj;    
    Lista_Rami(Pnt_Ramo_jj) = Ramo_jj;
end
Lista_Rami(ii)=Ramo_ii;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     POG=SWAP_POG(POG)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pog_Effort_Su=POG.pog_Effort_Su;
ABC=POG.Str_Type;
if strcmp(POG.TR_o_GY,'T')      % Se il blocco � un "Trasformatore" ... 
    if ((strcmp(ABC,'FFE')||strcmp(ABC,'EFE'))&&strcmp(pog_Effort_Su,'Si'))||...
            ((strcmp(ABC,'EEF')||strcmp(ABC,'FEF'))&&strcmp(pog_Effort_Su,'No'))
        POG=SU_GIU_POG(POG);
    end
elseif strcmp(POG.TR_o_GY,'G')  % Se il blocco � un "Giratore" ... (uguale al trasformatore)
    if ((strcmp(ABC,'FFE')||strcmp(ABC,'EFE'))&&strcmp(pog_Effort_Su,'Si'))||...
            ((strcmp(ABC,'EEF')||strcmp(ABC,'FEF'))&&strcmp(pog_Effort_Su,'No'))
        POG=SU_GIU_POG(POG);
    end
else    
    if (strcmp(ABC,'EFE')&&strcmp(pog_Effort_Su,'No'))||...
            (strcmp(ABC,'FEF')&&strcmp(pog_Effort_Su,'Si'))||...
            (strcmp(ABC,'EEF')&&strcmp(pog_Effort_Su,'No'))||...
            (strcmp(ABC,'FFE')&&strcmp(pog_Effort_Su,'Si'))||...
            (strcmp(ABC,'FEE')&&strcmp(pog_Effort_Su,'No'))||...
            (strcmp(ABC,'EFF')&&strcmp(pog_Effort_Su,'Si'))||...
            (strcmp(ABC,'EF0')&&strcmp(pog_Effort_Su,'No'))||...
            (strcmp(ABC,'FE0')&&strcmp(pog_Effort_Su,'Si'))||...
            (strcmp(ABC,'0EF')&&strcmp(pog_Effort_Su,'Si'))||...
            (strcmp(ABC,'0FE')&&strcmp(pog_Effort_Su,'No'))||...
            (strcmp(ABC,'EE0')&&strcmp(pog_Effort_Su,'Si'))||...
            (strcmp(ABC,'FF0')&&strcmp(pog_Effort_Su,'No'))
        POG=SU_GIU_POG(POG);
    end
end
if strcmp(POG.pog_Vai_a_Destra,'No')
    POG=DST_SNT_POG(POG);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function   POG=SU_GIU_POG(POG)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Altezza=POG.Altezza;
POG.Draw1=FLIP_DRAW_POG(POG.Draw1,Altezza,'su','giu');
%%%%%%%%%%%%%%%%
X2=POG.X2;
X2=X2-(Altezza*1i-1i);
POG.X2=X2;
%%%%%%%%%%%%%%%%
POG.Draw2=FLIP_DRAW_POG(POG.Draw2,0,'su','giu');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     POG=DST_SNT_POG(POG)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
POG.Draw1=FLIP_DRAW_POG(POG.Draw1,0,'dst','snt');
X2=POG.X2;
POG.X2=-conj(X2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     POG=SHAPE_DRAW_1(POG)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Altezza=POG.Altezza;
Lx_Dst=POG.Lx_Dst;
Lx_Snt=POG.Lx_Snt;
ABC=POG.Str_Type;
Nero=0; Color_In=1; Color_Block=2; Color_Out=3; Color_TG=4;
if ismember(POG.TR_o_GY,{'T','G'})          % Trasformatori o Giratori
    pog_Block_M_dx=POG.pog_Block_M_dx;
    pog_Block_M_dy=POG.pog_Block_M_dy;
    DX=(Lx_Snt+Lx_Dst-pog_Block_M_dx)/2;    % Lunghezza delle frecce nei blocchi TG
    Draw={...           % 'Command', Points, Color,...
        ... % Ramo alto             % Blocco "XEF"
        'vector2' ,[0+0*1i DX+0*1i], Color_TG,...
        'box'     ,MAKE_ORIENTED_BOX(DX,pog_Block_M_dx,pog_Block_M_dy,'dst'), Color_TG,...
        'Kn_in_TG',DX+pog_Block_M_dx/2+0*1i, Nero,...
        'vector1' ,[DX+pog_Block_M_dx+0*1i 2*DX+pog_Block_M_dx+0*1i], Color_TG,...
        ... % Ramo basso
        'vector2' ,[2*DX+pog_Block_M_dx-Altezza*1i DX+pog_Block_M_dx-Altezza*1i], Color_TG,...
        'box'     ,MAKE_ORIENTED_BOX(DX+pog_Block_M_dx-Altezza*1i,pog_Block_M_dx,pog_Block_M_dy,'snt'), Color_TG,...
        'Kn_in_TG',DX+pog_Block_M_dx/2-Altezza*1i, Nero,...
        'vector1' ,[DX-Altezza*1i 0-Altezza*1i], Color_TG,...
        };
else                                % ... tutti gli altri blocchi
    switch ABC
        case {'EFE','FEF'}
            Draw={...
                'vector2' ,[0+0*1i (Lx_Snt-0.5)+0*1i ], Color_In,...
                'piu'     ,Lx_Snt+GET_PUNTI_PIU(-1i), Color_In,...
                'dst'     ,Lx_Snt+0*1i, Color_In,...
                'vector2' ,[(Lx_Snt+Lx_Dst)+0*1i (Lx_Snt+0.5)+0*1i ], Color_In,...
                'vector'  ,[Lx_Snt-Altezza*1i 0-Altezza*1i], Color_Out,...
                'dot'     ,Lx_Snt-Altezza*1i, Color_Out,...
                'vector'  ,[Lx_Snt-Altezza*1i (Lx_Snt+Lx_Dst)-Altezza*1i], Color_Out,...
                };
        case {'EEF','FFE'}
            Draw={...
                'vector2' ,[0+0*1i (Lx_Snt-0.5)+0*1i ], Color_Out,...
                'piu'     ,Lx_Snt+GET_PUNTI_PIU(1), Color_Out,...
                'giu'     ,Lx_Snt+0*1i, Color_Out,...
                'vector1' ,[(Lx_Snt+0.5)+0*1i (Lx_Snt+Lx_Dst)+0*1i], Color_Out,...
                'vector'  ,[Lx_Snt-Altezza*1i 0-Altezza*1i], Color_In,...
                'dot'     ,Lx_Snt-Altezza*1i, Color_In,...
                'vector'  ,[(Lx_Snt+Lx_Dst)-Altezza*1i Lx_Snt-Altezza*1i], Color_In,...
                };
        case {'FEE','EFF'}
            Draw={...
                'vector2' ,[(Lx_Snt+Lx_Dst)+0*1i (Lx_Snt+0.5)+0*1i ], Color_Out,...
                'piu'     ,Lx_Snt+GET_PUNTI_PIU(-1), Color_Out,...
                'vector1' ,[(Lx_Snt-0.5)+0*1i 0+0*1i], Color_Out,...
                'vector'  ,[0-Altezza*1i Lx_Snt-Altezza*1i], Color_In,...
                'dot'     ,Lx_Snt-Altezza*1i, Color_In,...
                'vector'  ,[Lx_Snt-Altezza*1i (Lx_Snt+Lx_Dst)-Altezza*1i], Color_In,...
                };
        case {'EF0','FE0','FF0','EE0'}      % Blocchi finali a destra 
            if POG.Nome_Ramo(2)=='U'        % Nel caso di generatori ...
                Draw={...
                    'V_In_snt'  ,0.25+0*1i, Nero,...
                    'V_Out_snt' ,0.25-Altezza*1i, Nero,...
                    'V_IN_snt'  ,MAKE_ORIENTED_BOX(0-0*1i,2.0,2.0,'dst'), Color_Block,...
                    'V_OUT_snt' ,MAKE_ORIENTED_BOX(0-Altezza*1i,2.0,2.0,'dst'), Color_Block,...
                    };
            else                        % ... per tutti gli altri blocchi
                Draw={...
                    'line'  ,[0+0*1i Lx_Snt+0*1i Lx_Snt-0.5*1i], Color_In,...
                    'vector',[Lx_Snt-Altezza*1i 0-Altezza*1i], Color_Out,...
                    };
            end
        case {'0FE','0EF','0FF','0EE'}  % Blocchi finali a sinistra
            if POG.Nome_Ramo(2)=='U'    % Nel caso di generatori ...
                Draw={...
                    'V_In_snt'  ,0.25+0*1i, Nero,...
                    'V_Out_snt' ,0.25-Altezza*1i, Nero,...
                    'V_IN_snt'  ,MAKE_ORIENTED_BOX(0-0*1i,2.0,2.0,'dst'), Color_Block,...
                    'V_OUT_snt' ,MAKE_ORIENTED_BOX(0-Altezza*1i,2.0,2.0,'dst'), Color_Block,...
                    };
            else                        % ... per tutti gli altri blocchi
                Draw={...
                    'vector2'   ,[0+0*1i (Lx_Snt-0.5)+0*1i ], Color_In,...
                    'piu'       ,Lx_Snt+GET_PUNTI_PIU(-1i), Color_In,...
                    'snt'       ,Lx_Snt+0*1i, Color_In,...
                    'vector2'   ,[(Lx_Snt+Lx_Dst)+0*1i (Lx_Snt+0.5)+0*1i ], Color_In,...
                    'vector'    ,[Lx_Snt-Altezza*1i 0-Altezza*1i], Color_Out,...
                    'dot'       ,Lx_Snt-Altezza*1i, Color_Out,...
                    'vector'    ,[Lx_Snt-Altezza*1i (Lx_Snt+Lx_Dst)-Altezza*1i], Color_Out,...
                    'tratteggio',(Lx_Snt+Lx_Dst)+0*1i+[0+0.5*1i 0-(Altezza+0.5)*1i], Nero,...                    
                    'dot'       ,(Lx_Snt+Lx_Dst)+0*1i, Color_In,... 
                    'dot'       ,(Lx_Snt+Lx_Dst)+0*1i-Altezza*1i, Color_Out,...
                    'Zero_snt'  ,(Lx_Snt+Lx_Dst+0.2)+0*1i, Nero
                    };
            end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Aggiunge gli elementi grafici di X1_Shift 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if strcmp(POG.Nome_Ramo,'SP')      % Solo i Rami SP hanno la variabile 'X1_Shift' definita     
        switch ABC
            case {'EFE','FEF'}
                Draw=[ Draw, 'vector1',Lx_Snt+[0-0.5*1i 0-imag(POG.X1_Shift)*1i conj(POG.X1_Shift)], Color_In ...
                             'vector',Lx_Snt+[POG.X1_Shift 0+imag(POG.X1_Shift)*1i 0+0*1i]-Altezza*1i, Color_Out];
            case {'EEF','FFE','FEE','EFF'}
                Draw=[ Draw, 'vector2',Lx_Snt+[conj(POG.X1_Shift) 0-imag(POG.X1_Shift)*1i 0-0.5*1i], Color_Out ...
                             'vector',Lx_Snt+[0+0*1i 0+imag(POG.X1_Shift)*1i POG.X1_Shift ]-Altezza*1i, Color_In];
        end
    end
end
% disp(POG)
%  disp(ABC)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Aggiunge il tratteggio
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(POG.pog_Vai_a_Destra,'Si')
    Draw=[ Draw, 'dot'  ,0+0*1i, Color_In,...
                 'dot'  ,0-Altezza*1i, Color_Out,...
                 'tratteggio', [0+0.5*1i 0-(Altezza+0.5)*1i], Nero,...
                 'NrR_snt'   ,0.1-0.1*Altezza*1i, Nero ...
                 ];
end
POG.Draw1=Draw;
POG.X2=POG.X1+Lx_Snt-0.5*1i;
POG.X3=POG.X1+(Lx_Snt+Lx_Dst);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     POG=SHAPE_DRAW_2(POG)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Altezza=POG.Altezza;
pog_Block_M_dx=POG.pog_Block_M_dx;
pog_Block_M_dy=POG.pog_Block_M_dy;
pog_Block_S_dx=POG.pog_Block_S_dx;
pog_Block_S_dy=POG.pog_Block_S_dy;
Nero=0; Color_In=1; Color_Block=2; Color_Out=3;
if not(isempty(POG.TR_o_GY))        % I Trasformatori e Giratori non hanno parte DRAW_2
    Draw={};
else                                % Per tutti gli altri blocchi ...
    ABC=POG.Str_Type;
    if strcmp(POG.MxM,'Si')         % Per i blocchi dinamici ...
        pog_From_S_to_M_dy=(Altezza-pog_Block_M_dy-pog_Block_S_dy-0.5)/3;
        if strcmp(POG.pog_IntM,'Si')  % Prima l'integratore e poi la relazione costitutiva M ...
            Draw={...           
                'vectorx2'    ,[0+0*1i 0-pog_From_S_to_M_dy*1i], Color_In,...
                'V_In_snt_giu',0.15-(0.9*pog_From_S_to_M_dy)*1i, Nero,...
                'box_Int'     ,MAKE_ORIENTED_BOX(0-pog_From_S_to_M_dy*1i,pog_Block_S_dy,pog_Block_S_dx,'giu'), Color_Block,...
                'Int_in_S'    ,0-(pog_From_S_to_M_dy+pog_Block_S_dy/2)*1i, Nero,...
                'vector12'    ,[0-(pog_From_S_to_M_dy+pog_Block_S_dy)*1i 0-(2*pog_From_S_to_M_dy+pog_Block_S_dy)*1i], Color_Block,...
                'V_Q_snt'     ,0.15-(1.5*pog_From_S_to_M_dy+pog_Block_S_dy)*1i, Nero,...
                'box'         ,MAKE_ORIENTED_BOX(0-(2*pog_From_S_to_M_dy+pog_Block_S_dy)*1i,pog_Block_M_dy,pog_Block_M_dx,'giu'), Color_Block,...
                'Kn_in_M'     ,0-(2*pog_From_S_to_M_dy+pog_Block_S_dy+pog_Block_M_dy/2)*1i, Nero,...
                'vector1x'    ,[0-(2*pog_From_S_to_M_dy+pog_Block_S_dy+pog_Block_M_dy)*1i 0-(3*pog_From_S_to_M_dy+pog_Block_S_dy+pog_Block_M_dy)*1i], Color_Out,...
                };
        else                        % Prima la relazione costitutiva M e poi l'integratore
            Draw={...                      
                'vectorx2'    ,[0+0*1i 0-pog_From_S_to_M_dy*1i], Color_In,...
                'V_In_snt_giu',0.15-(0.9*pog_From_S_to_M_dy)*1i, Nero,...
                'box'         ,MAKE_ORIENTED_BOX(0-pog_From_S_to_M_dy*1i,pog_Block_M_dy,pog_Block_M_dx,'giu'), Color_Block,...
                'Kn_in_M'     ,0-(pog_From_S_to_M_dy+pog_Block_M_dy/2)*1i, Nero,...
                'vector12'    ,[0-(pog_From_S_to_M_dy+pog_Block_M_dy)*1i 0-(2*pog_From_S_to_M_dy+pog_Block_M_dy)*1i], Color_Block,...
                'V_Q_snt'     ,0.15-(1.5*pog_From_S_to_M_dy+pog_Block_M_dy)*1i, Nero,...
                'box_Int'     ,MAKE_ORIENTED_BOX(0-(2*pog_From_S_to_M_dy+pog_Block_M_dy)*1i,pog_Block_S_dy,pog_Block_S_dx,'giu'), Color_Block,...
                'Int_in_S'    ,0-(2*pog_From_S_to_M_dy+pog_Block_M_dy+pog_Block_S_dy/2)*1i, Nero,...
                'vector1x'    ,[0-(2*pog_From_S_to_M_dy+pog_Block_S_dy+pog_Block_M_dy)*1i 0-(3*pog_From_S_to_M_dy+pog_Block_S_dy+pog_Block_M_dy)*1i], Color_Out,...
                };
        end
        if strcmp(ABC,'EFE')||strcmp(ABC,'FEF')
            Draw=[ Draw, 'V_Out_su' ,0-(3*pog_From_S_to_M_dy+pog_Block_S_dy+pog_Block_M_dy+0.1)*1i, Nero];
        else
            Draw=[ Draw, 'V_Out_snt_su' ,0.15-(2.1*pog_From_S_to_M_dy+pog_Block_S_dy+pog_Block_M_dy)*1i, Nero];
        end
    else
        pog_From_S_to_M_dy=(Altezza-pog_Block_M_dy-0.5)/2;
        if POG.Nome_Ramo(2)=='U'            % Se il blocco � un ingresso ...
            Draw={...
                'vector'    ,[0+0*1i 0-0.5*pog_From_S_to_M_dy*1i], Color_In,...
                'dot'       ,0-0.5*pog_From_S_to_M_dy*1i, Color_In,...
                'V_In_su'  ,0-(0.5*pog_From_S_to_M_dy+0.15)*1i, Nero,...
                'V_Out_giu'  ,0-(1.5*pog_From_S_to_M_dy+pog_Block_M_dy-0.15)*1i, Nero,...
                'dot'       ,0-(1.5*pog_From_S_to_M_dy+pog_Block_M_dy)*1i, Color_Out,...
                'vector'    ,[0-(1.5*pog_From_S_to_M_dy+pog_Block_M_dy)*1i 0-(2*pog_From_S_to_M_dy+pog_Block_M_dy)*1i], Color_Out,...
                'V_IN_su'   ,MAKE_ORIENTED_BOX(0-0.5*pog_From_S_to_M_dy*1i,2.0,2.0,'giu'), Color_Block,...
                'V_OUT_giu' ,MAKE_ORIENTED_BOX(0-(1.5*pog_From_S_to_M_dy+pog_Block_M_dy)*1i,2.0,2.0,'su'), Color_Block,...
                };
        else
            Draw={...
                'V_In_snt_giu' ,0.15-(0.85*pog_From_S_to_M_dy)*1i, Nero,...
                'box'      ,MAKE_ORIENTED_BOX(0-pog_From_S_to_M_dy*1i,pog_Block_M_dy,pog_Block_M_dx,'giu'), Color_Block,...
                'Kn_in_M'  ,0-(pog_From_S_to_M_dy+pog_Block_M_dy/2)*1i, Nero,...
                'vectorx2' ,[0+0*1i 0-pog_From_S_to_M_dy*1i], Color_In,...
                'vector1x' ,[0-(pog_From_S_to_M_dy+pog_Block_M_dy)*1i 0-(2*pog_From_S_to_M_dy+pog_Block_M_dy)*1i], Color_Out,...
                'V_Out_snt_su',0.15-(1.15*pog_From_S_to_M_dy+pog_Block_M_dy)*1i, Nero,...
                };            
        end
    end
    % Per i seguenti blocchi la parte interna deve essere 'girata' su/giu
    switch ABC
        case {'FEE','EFF','FFE','EEF'}
            Draw=FLIP_DRAW_POG(Draw,(Altezza-0.5),'su','giu');
        case {'EF0','FE0','FF0','EE0','0FE','0EF','0FF','0EE'}
            if POG.Nome_Ramo(2)=='U'
                Draw={};
            end
    end
end
POG.Draw2=Draw;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     box=MAKE_ORIENTED_BOX(x0,dx,dy,Direction)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
box=[ 0 dy/2*1i dx+dy/2*1i dx dx-dy/2*1i -dy/2*1i 0];
switch Direction
    case 'dst'
        box=x0+box;
    case 'snt'
        box=x0-box;
    case 'su'
        box=x0+box*1i;
    case 'giu'
        box=x0-box*1i;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function   Draw=FLIP_DRAW_POG(Draw,Altezza,Str1,Str2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ismember(Str1,{'su','giu'})
    PiuMeno=1;
elseif ismember(Str1,{'dst','snt'})
    PiuMeno=-1;
    Altezza=0;
end
for ii=2:3:length(Draw)
    Draw{ii-1}=strrep(Draw{ii-1},Str1,'xxx');
    Draw{ii-1}=strrep(Draw{ii-1},Str2,Str1);
    Draw{ii-1}=strrep(Draw{ii-1},'xxx',Str2);
    Draw{ii}=PiuMeno*conj(Draw{ii})-Altezza*1i;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     SHOW_RAMI_POG(Show_Lista_Rami_SP,Lista_Rami,ii)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ramo_ii=Lista_Rami(ii);                 % Ramo_ii e' sempre di tipo SP
Nr_SP_Rami=length(Ramo_ii.SP_Rami);
for jj=1:Nr_SP_Rami                     % jj cicla in modo inverso su tutti i rami contenuti in "Ramo_ii.SP_Rami"
    Pnt_Ramo_jj=Ramo_ii.SP_Rami(jj);    % Pnt_Ramo_jj e' il puntatore al jj-esimo ramo in "Ramo_ii.SP_Rami" 
    Ramo_jj=Lista_Rami(Pnt_Ramo_jj);    % Ramo_jj contiene tutti i parametri del jj-esimo ramo 
    POG_jj=Ramo_jj.POG;
    Ramo_jj.Nr_Ramo=Pnt_Ramo_jj;
%     if strcmp(Lista_Rami(Pnt_Ramo_jj).Nome_Ramo,'SP')
%         Lista_Rami(Pnt_Ramo_jj).Dominio=Lista_Rami(jj).Dominio;
%     end
    Ramo_jj.Dominio=GET_DOMINIO(Lista_Rami,Pnt_Ramo_jj);
    if strcmp(Show_Lista_Rami_SP,'Si')
        disp([Ramo_jj.Nome_Ramo ', ' num2str(Pnt_Ramo_jj) ', ' Lista_Rami(Pnt_Ramo_jj).TR_o_GY ', ' Ramo_jj.Dominio])
    end
    SHOW_DRAW(POG_jj.X1,POG_jj.Draw1,Ramo_jj)       % Graficazione della parte "esterna"
    SHOW_DRAW(POG_jj.X2,POG_jj.Draw2,Ramo_jj)       % Graficazione della parte "interna"
    if not(strcmp(Ramo_jj.SP,'Foglia'))
        SHOW_RAMI_POG(Show_Lista_Rami_SP,Lista_Rami,Pnt_Ramo_jj)
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [Color_0, Color_1, Color_2, Color_3, Color_4] = GET_COLORS(Ramo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Colored=Ramo.POG.pog_Colored;
Color_0=[0 0 0];                    % Default black color
if strcmp(Colored,'Si')             % Se il blocco � colorato ...
    if isempty(Ramo.Dominio)                % Se il ramo non ha un dominio definito ...
        Color_2=Color_0;                    % ... il colore del blocco centrale � nero
    else                                                            % ... altrimenti ...
        Color_2=eval(['Ramo.POG.pog_Color_' Ramo.Dominio ';']);     % ... il colore del blocco centrale � quello assegnato al dominio
    end
    Color_4=Ramo.POG.pog_Color_4;           % Colore dei blocchi Trasformatori e Giratori
else                                % ... se invece il blocco NON � colorato ... 
    Color_2=Color_0;                %     1) il blocco centrale � nero 
    Color_4=Color_0;                %     2) i blocchi TG sono neri
end
Color_1=Color_2;            % Colore delle variabili di ingresso
Color_3=Color_2;            % Colore delle variabili di uscita
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Color_box=GET_COLOR_BOX(Color)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
GoUp=0.9;
Color_box=GoUp*[1 1 1]+(1-GoUp)*Color;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     SHOW_DRAW(x0,Draw,Ramo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Line_Width=Ramo.POG.pog_Line_Width;
Line_Type=Ramo.POG.pog_Line_Type;
Visibile=Ramo.POG.pog_Visibile;
[Color_0, Color_1, Color_2, Color_3, Color_4] = GET_COLORS(Ramo);
[Input_Variable, Input_Color]=GET_COLOR_OF_INPUT_VARIABLE(Ramo);
[Output_Variable, ~, Output_Color]=GET_COLOR_OF_OUTPUT_VARIABLE(Ramo);
% Color_1=Input_Color;
% Color_3=Output_Color;
POG=Ramo.POG;
if strcmp(Visibile,'Si')
    for ii=1:3:length(Draw)
        Command=Draw{ii};                                   % Comando
        Points=x0+eps*1i+Draw{ii+1};                        % Punti
        Color=eval(['Color_' num2str(Draw{ii+2}) ',']);     % Colore
        switch Command
            case 'line'
                plot(Points,Line_Type,'LineWidth',Line_Width,'Color',Color)
            case {'box', 'box_Int'}
                Color_box=GET_COLOR_BOX(Color);
                if strcmp(Ramo.POG.pog_Colored,'Si')
                    patch(real(Points),imag(Points),Color_box,'EdgeColor',Color)
                else
                    plot(Points,Line_Type,'LineWidth',Line_Width,'Color',Color)
                end
            case {'vector','vector1','vector1x','vector2','vectorx2','vector12'}
                plot(Points,Line_Type,'LineWidth',Line_Width,'Color',Color)
                vet=Points(end)-Points(end-1);  % Vettore
                ver=vet/norm(vet);              % Versore
                xx=Points(end)+0.4*ver*[0 exp(1i*(180-25)*pi/180) exp(1i*(180+25)*pi/180)]; % Freccia
                patch(real(xx),imag(xx),Color,'EdgeColor',Color)    % Graicazione Freccia
            case {'Split_Sopra_Out','Split_Sotto_In','Split_Sotto_Out','Split_Sopra_In'}
               if strcmp(Ramo.POG.Split_POG_Show_Lines,'Si')
                    plot(Points,Line_Type,'LineWidth',Line_Width,'Color',Color)
                    vet=Points(end)-Points(end-1);
                    ver=vet/norm(vet);
                    xx=Points(end)+0.4*ver*[0 exp(1i*(180-25)*pi/180) exp(1i*(180+25)*pi/180)];
                    patch(real(xx),imag(xx),Color,'EdgeColor',Color)
               end
            case 'piu'
                Centro=mean(Points);
                Raggio=(max(real(Points))-min(real(Points)))/2;
                plot(Points,Line_Type,'LineWidth',Line_Width,'Color',Color)
%                 Color_box=GET_COLOR_BOX(Color);
%                 patch(real(Punti),imag(Punti),Color_box,'EdgeColor',Color)
                plot(Centro+Raggio*exp([1 5]*pi/4*1i),Line_Type,'LineWidth',Line_Width,'Color',Color)
                plot(Centro+Raggio*exp([3 7]*pi/4*1i),Line_Type,'LineWidth',Line_Width,'Color',Color)
            case 'dot'
                xx=Points+0.06*exp(1i*2*pi*(0:0.01:1));
                patch(real(xx),imag(xx),Color,'EdgeColor',Color)
            case 'su'
                rho=0.16;       % rho=0.5/(1+sqrt(2));
                xx=Points+(0.45-rho)*1i+rho*exp(1i*2*pi*(0:0.01:1));
                patch(real(xx),imag(xx),Color,'EdgeColor',Color)
            case 'giu'
                rho=0.16;
                xx=Points-(0.45-rho)*1i+rho*exp(1i*2*pi*(0:0.01:1));
                patch(real(xx),imag(xx),Color,'EdgeColor',Color)
            case 'dst'
                rho=0.16;
                xx=Points+(0.45-rho)+rho*exp(1i*2*pi*(0:0.01:1));
                patch(real(xx),imag(xx),Color,'EdgeColor',Color)
            case 'snt'
                rho=0.16;
                xx=Points-(0.45-rho)+rho*exp(1i*2*pi*(0:0.01:1));
                patch(real(xx),imag(xx),Color,'EdgeColor',Color)
            case 'tratteggio'
                if strcmp(POG.pog_Show_T,'Si')
                    plot(Points,POG.pog_Color_T,'LineWidth',POG.pog_Width_T)
                end
            case {'V_Q','V_Q_snt','V_Q_su','V_Q_giu','V_Q_snt_su','V_Q_snt_giu','V_Q_dst','V_Q_dst_su','V_Q_dst_giu'}
                if strcmp(POG.pog_Show_Q,'Si')
                    String=char(Ramo.Q_name);
                    PLOT_TEXT(Points,String,Command,POG.pog_Font_Q,POG.pog_Color_Q,POG)
                end
            case {'V_In','V_In_snt','V_In_su','V_In_giu','V_In_snt_su','V_In_snt_giu','V_In_dst','V_In_dst_su','V_In_dst_giu'}
                if strcmp(POG.pog_Show_Y,'Si')||(POG.Nome_Ramo(2)=='U')
                    PLOT_TEXT(Points,Input_Variable,Command,POG.pog_Font_Y,Input_Color,POG)
                end
            case {'V_Out','V_Out_snt','V_Out_su','V_Out_giu','V_Out_snt_su','V_Out_snt_giu','V_Out_dst','V_Out_dst_su','V_Out_dst_giu'}
                if strcmp(POG.pog_Show_X,'Si')
                    PLOT_TEXT(Points,Output_Variable,Command,POG.pog_Font_X,Output_Color,POG)
                end
            case {'NrR_giu','NrR_su','NrR_snt','NrR_dst'}
                if strcmp(POG.pog_Show_Nome_Ramo,'Si')
                    PLOT_TEXT(Points,num2str(Ramo.Nr_Ramo),Command,POG.pog_Font_Nome_Ramo,POG.pog_Color_Nome_Ramo,POG)
                end
            case {'Dots_snt','Dots_dst'}
                    PLOT_TEXT(Points,'...',Command,18,'k',POG)                
            case 'Kn_in_M'
                if strcmp(POG.pog_Show_K,'Si')
                    String=char(GET_KN(Ramo));
                    PLOT_TEXT(Points,String,Command,POG.pog_Font_K,POG.pog_Color_K,POG)
                end
            case {'Zero_dst','Zero_snt'}
                PLOT_TEXT(Points,'0',Command,POG.pog_Font_X,POG.pog_Color_X,POG)
%                text(real(Points),imag(Points),'0','HorizontalAlignment','right','VerticalAlignment','middle')                
%             case 'Zero_snt'
%                text(real(Points),imag(Points),'0','HorizontalAlignment','left','VerticalAlignment','middle')                
            case 'Int_in_S'
                PLOT_TEXT(Points,'1/s',Command,POG.pog_Font_K,POG.pog_Color_K,POG)
%                text(real(Points),imag(Points),'1/s','HorizontalAlignment','center','VerticalAlignment','middle')
            case 'Kn_in_TG'
                Kn = CALCOLA_PARAMETRO_KN_DI_T_G(Ramo);
                String=char(Kn);
                PLOT_TEXT(Points,String,Command,POG.pog_Font_K,POG.pog_Color_K,POG)
%                text(real(Points),imag(Points),String,'HorizontalAlignment','center','VerticalAlignment','middle')
            case {'V_IN_snt','V_OUT_snt','V_IN_dst','V_OUT_dst','V_IN_su','V_OUT_su','V_IN_giu','V_OUT_giu'}
                % Non si fa nulla
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     Dominio=GET_DOMINIO(Lista_Rami,jj)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(Lista_Rami(jj).Dominio)
%    if isempty(Lista_Rami(jj).TR_o_GY)
        Dominio=GET_DOMINIO(Lista_Rami,Lista_Rami(jj).SP_Rami(1));
%     else
%         Dominio=Lista_Rami(jj+Lista_Rami(jj).Gemello).Dominio;
%     end
else
    Dominio=Lista_Rami(jj).Dominio;
end    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     Sistema = CREA_LO_SCHEMA_SIMULINK(Sistema)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SLX_Name=[Sistema.Grafico.Nome_del_grafico '_SLX'];
Ind=strfind(SLX_Name,'.');
if not(isempty(Ind))
    SLX_Name=SLX_Name(1:Ind(1)-1);
end
if bdIsLoaded(SLX_Name)
    save_system(SLX_Name)
    close_system(SLX_Name)
end
if exist([SLX_Name '.slx'],'file')
    delete([SLX_Name '.slx'])
end
Sistema.SLX.Name=SLX_Name;
new_system(SLX_Name);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CREA LO SCHEMA SIMULINK  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Partizione=Sistema.Partizione;
for ii=Sistema.Input_POG
    Ind=NR_PARTIZIONE_CHE_CONTIENE_IL_RAMO(Partizione,ii);
    Pnt_Ramo_ii=Partizione(Ind).Ultimo_Ramo;
    CREA_BLOCCHI_SLX(Sistema,Pnt_Ramo_ii);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%  ADD THE TIME VARIABLE 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
add_block('built-in/To Workspace',[SLX_Name '/Time'],'Position',[75   162   100   188],'VariableName','t','Orientation','right','ShowName','off','MaxDataPoints','10000','SampleTime','Ts');            
add_block('built-in/Clock',[SLX_Name '/Clock'],'Position',[35   165    55   185],'Orientation','right','ShowName','off');            
add_line(SLX_Name,'Clock/1','Time/1')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_param(SLX_Name,'Solver','ode45','LimitDataPoints','off','MaxStep','0.001')
save_system([Sistema.Grafico.Dir_out SLX_Name])
if strcmp(Sistema.POG_SYS.slx_Print_SLX,'Si')
    PRINT_FIGURA([Sistema.Grafico.Dir_out Sistema.Grafico.Nome_del_grafico],Sistema.POG_SYS.pog_Graphic_Type,'_SLX')
end
close_system(SLX_Name)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%  Crea il file "Nome_del_grafico.m"
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fh=fopen([Sistema.Grafico.Dir_out Sistema.Grafico.Nome_del_grafico '_SLX_m.m'],'w');
mywrite(fh, ' clear all; close all');
mywrite(fh, ' %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
mywrite(fh,[' %%%% SIMULATION OF SYSTEM: ' Sistema.Grafico.Nome_del_grafico ]);
mywrite(fh, ' %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
Parametri=Sistema.Parametri;
mywrite(fh, ' %%%%%%%%%%%%   SYSTEM PARAMETERS  %%%%%%%%%%%%%%%%%%%%%%%%%%');
for ii=1:length(Parametri)
    if strcmp(Parametri(ii).Type,'Kn0')
            mywrite(fh,[' ' Parametri(ii).Line]);
    end
end
mywrite(fh, ' %%%%%%%%%%%%   INPUT VALUES  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
for ii=1:length(Parametri)
    if strcmp(Parametri(ii).Type,'U0')
            mywrite(fh,[' ' Parametri(ii).Line]);
    end
end
mywrite(fh, ' %%%%%%%%%%%%   INITIAL CONDITIONS  %%%%%%%%%%%%%%%%%%%%%%%%%');
for ii=1:length(Parametri)
    if strcmp(Parametri(ii).Type,'Qn0')
            mywrite(fh,[' ' Parametri(ii).Line]);
    end
end
mywrite(fh,  ' %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
mywrite(fh, [' Tfin=' num2str(Sistema.POG_SYS.sim_Tfin) ';']);
mywrite(fh, [' Nr_Ts_Points=' num2str(Sistema.POG_SYS.sim_Nr_Ts_Points) ';']);
mywrite(fh,  ' Ts=Tfin/Nr_Ts_Points;');
mywrite(fh, [' SLX_Name = ''' SLX_Name ''';']);
mywrite(fh,  ' Out_Sim=sim(SLX_Name,''stoptime'',num2str(Tfin),''SaveOutput'',''on'',''SaveTime'',''off'');');
mywrite(fh,  ' %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
mywrite(fh,  ' Variables=Out_Sim.get;');
mywrite(fh,  ' Variables=setdiff(Variables,''t'');');
mywrite(fh,  ' Nr_Var=length(Variables);');
mywrite(fh,  ' t=Out_Sim.get(''t'');');
mywrite(fh,  ' %%%%%% PLOT THE OUTPUP VARIABLES Y  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
mywrite(fh,  ' S=[2,1]; Ns=S(1)*S(2); Nr=Ns;');
mywrite(fh,  ' for ii=1:Nr_Var; Unit(ii)={''1''}; Var(ii)={[''Var\_'' num2str(ii)]}; end');
mywrite(fh,  ' for ii=0:Ns:Nr_Var');
mywrite(fh,  '     if ii+Ns>Nr_Var; Nr=Nr_Var-ii; end');
mywrite(fh,  '     for jj=1:Nr');
mywrite(fh,  '         figure(900+ii/Ns)');
mywrite(fh,  '         y=Out_Sim.get(Variables{ii+jj});');
mywrite(fh,  '         subplot(S(1),S(2),jj)');
mywrite(fh,  '         plot(t,y/eval([''('' Unit{ii+jj} '')''])); grid on');
mywrite(fh,  '         ylabel([strrep(Variables{ii+jj},''_'',''\_'') '' ['' Unit{ii+jj} '']''])');
mywrite(fh,  '         title(Var{ii+jj})');
mywrite(fh,  '         if jj>Nr-S(2); xlabel(''Time [s]''); end');
mywrite(fh,  '     end');
mywrite(fh,  ' end');
fclose(fh);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sistema.Schema_SLX_Generato='Si';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function     CREA_BLOCCHI_SLX(Sistema,Pnt_Ramo_ii)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Lista_Rami=Sistema.Lista_Rami;
Ramo_ii=Lista_Rami(Pnt_Ramo_ii);        % Ramo_ii e' sempre di tipo SP
Nr_SP_Rami=length(Ramo_ii.SP_Rami);
for jj=1:Nr_SP_Rami                     % jj cicla in modo inverso su tutti i rami contenuti in "Ramo_ii.SP_Rami"
    Pnt_Ramo_jj=Ramo_ii.SP_Rami(jj);    % Pnt_Ramo_jj e' il puntatore al jj-esimo ramo in "Ramo_ii.SP_Rami" 
    Ramo_jj=Lista_Rami(Pnt_Ramo_jj);    % Ramo_jj contiene tutti i parametri del jj-esimo ramo 
    POG_jj=Ramo_jj.POG;
    Ramo_jj.Nr_Ramo=Pnt_Ramo_jj;        % Memorizza in Ramo_jj anche il puntatore al ramo stesso
    Ramo_jj.Dominio=GET_DOMINIO(Lista_Rami,Pnt_Ramo_jj);
    DRAW_BLOCCO_SLX(POG_jj.X1,POG_jj.Draw1,Ramo_jj,Sistema.SLX)         % Graficazione della parte "esterna"
    DRAW_BLOCCO_SLX(POG_jj.X2,POG_jj.Draw2,Ramo_jj,Sistema.SLX)         % Graficazione della parte "interna"
    if not(strcmp(Ramo_jj.SP,'Foglia'))
        CREA_BLOCCHI_SLX(Sistema,Pnt_Ramo_jj)
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function         DRAW_BLOCCO_SLX(x0,Draw,Ramo,SLX)       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Nr_box='';      % Se ci sono due 'box' nello stesso elemento il primo � quello di default
[Input_Variable, Input_Color]=GET_COLOR_OF_INPUT_VARIABLE(Ramo);
[Output_Variable, ~, Output_Color]=GET_COLOR_OF_OUTPUT_VARIABLE(Ramo);
[Color_0, Color_1, Color_2, Color_3, Color_4] = GET_COLORS(Ramo);
for ii=1:3:length(Draw)
    Command=Draw{ii};                                   % Comando
    Points=CONVERT_POINTS(x0+eps*1i+Draw{ii+1});        % Punti in coordinate SLX
    Color=eval(['Color_' num2str(Draw{ii+2}) ',']);     % Colore
    Color_box=GET_COLOR_BOX(Color);
    Ext_t='';                           % Ext_t='_t'; Added extension in the Input/Output Simulink blocks
    switch Command
        case 'box_Int'
            [Range_Block, Orientation]=GET_RANGE_AND_ORIENTATION(Points);
            h=add_block('built-in/Integrator',[SLX.Name '/Int' num2str(Ramo.Nr_Ramo)],'InitialCondition',[Ramo.Q_name '_0'],'position',Range_Block,'Orientation',Orientation,'ShowName','off','BackgroundColor',['[' num2str(Color_box) ']']);            
        case 'box'
            [Range_Block, Orientation]=GET_RANGE_AND_ORIENTATION(Points);
            Km=GET_KN(Ramo);
            add_block('built-in/Gain',[SLX.Name '/Gain' num2str(Ramo.Nr_Ramo) Nr_box],'Gain',char(Km),'position',Range_Block,'Orientation',Orientation,'ShowName','off','BackgroundColor',['[' num2str(Color_box) ']']);
            Nr_box='1';     % Se ci sono due 'box' nello stesso elemento al nome del secondo viene aggiunto '1'
        case 'piu'
            [Range_Block, Orientation, Inputs]=GET_PIU_RANGE_AND_ORIENTATION(Points);
            add_block('built-in/Sum',[SLX.Name '/Sum' num2str(Ramo.Nr_Ramo)],'position',Range_Block,'Orientation',Orientation,'IconShape','round','Inputs',Inputs,'ShowName','off','BackgroundColor',['[' num2str(Color_box) ']']);            
        case {'vector','vector1','vector1x','vector2','vectorx2','vector12','Split_Sopra_Out','Split_Sotto_In','Split_Sotto_Out','Split_Sopra_In'}
            switch Command
                case {'vector1','vector1x','vector12'}      % Vettori che nel punto di partenza escono da un blocco
                    Points(1)=Points(1)+5*(Points(2)-Points(1))/abs((Points(2)-Points(1))); 
            end     % La coda (il punto di partenza) del vettore viene accorciata di 5 punti
            switch Command
                case {'vector2','vectorx2','vector12'}      % Vettori che nel punto di arrivo entrano in un blocco
                    Points(end)=Points(end)-5*(Points(end)-Points(end-1))/abs((Points(end)-Points(end-1)));                     
            end     % La punta (il punto di arrivo) del vettore viene accorciata di 5 punti
            switch Command
                case 'vector1x'         % Vettori che nel punto di arrivo entrano in un blocco
                    switch Ramo.POG.Str_Type
                        case {'FEE','EFF','EEF','FFE'}
                            Points(end)=Points(end)-5*(Points(end)-Points(end-1))/abs((Points(end)-Points(end-1)));
                    end     % La punta (il punto di arrivo) del vettore viene accorciata di 5 punti
                case 'vectorx2'         % Vettori che nel punto di partenza escono da un blocco
                    switch Ramo.POG.Str_Type
                        case {'EFE','FEF'}
                            Points(1)=Points(1)+5*(Points(2)-Points(1))/abs((Points(2)-Points(1)));
                    end
            end
            h=add_line(SLX.Name,GET_POINTS_VECTORS(Points));
            switch Command
                case 'vector1x'
                    set(h,'Name',Output_Variable)
%                 case 'vector12'       % Mostra le variabili energia
%                     set(h,'Name',Ramo.Q_name)
                case 'vectorx2'
                    if strcmp(Ramo.POG.MxM,'Si')
                        set(h,'Name',Input_Variable)
                    end
            end
        case 'line'
            add_line(SLX.Name,GET_POINTS_VECTORS(Points));            
        case 'V_IN_snt'
            [Range_Block,~]=GET_RANGE_AND_ORIENTATION(Points+5);
            add_block('built-in/To Workspace',[SLX.Name '/To_Work' num2str(Ramo.Nr_Ramo) Nr_box],'position',Range_Block,'VariableName',[Input_Variable Ext_t],'Orientation','right','ShowName','off','BackgroundColor',['[' num2str(Color_box) ']'],'MaxDataPoints','10000','SampleTime','Ts');            
        case 'V_OUT_snt'
            [Range_Block,~]=GET_RANGE_AND_ORIENTATION(Points+5);
            add_block('built-in/Constant',[SLX.Name '/Constant' num2str(Ramo.Nr_Ramo) Nr_box],'position',Range_Block,'Value',[Output_Variable Ext_t],'Orientation','left','ShowName','off','BackgroundColor',['[' num2str(Color_box) ']']);            
        case 'V_IN_dst'
            [Range_Block,~]=GET_RANGE_AND_ORIENTATION(Points-5);
            add_block('built-in/To Workspace',[SLX.Name '/To_Work' num2str(Ramo.Nr_Ramo) Nr_box],'position',Range_Block,'VariableName',[Input_Variable Ext_t],'Orientation','left','ShowName','off','BackgroundColor',['[' num2str(Color_box) ']'],'MaxDataPoints','10000','SampleTime','Ts');            
        case 'V_OUT_dst'
            [Range_Block,~]=GET_RANGE_AND_ORIENTATION(Points-5);
            add_block('built-in/Constant',[SLX.Name '/Constant' num2str(Ramo.Nr_Ramo) Nr_box],'position',Range_Block,'Value',[Output_Variable Ext_t],'Orientation','right','ShowName','off','BackgroundColor',['[' num2str(Color_box) ']']);            
        case 'V_IN_su'
            [Range_Block,~]=GET_RANGE_AND_ORIENTATION(Points+5*1i);
            add_block('built-in/To Workspace',[SLX.Name '/To_Work' num2str(Ramo.Nr_Ramo) Nr_box],'position',Range_Block,'VariableName',[Input_Variable Ext_t],'Orientation','down','ShowName','off','BackgroundColor',['[' num2str(Color_box) ']'],'MaxDataPoints','10000','SampleTime','Ts');            
        case 'V_OUT_giu'
            [Range_Block,~]=GET_RANGE_AND_ORIENTATION(Points-5*1i);
            add_block('built-in/Constant',[SLX.Name '/Constant' num2str(Ramo.Nr_Ramo) Nr_box],'position',Range_Block,'Value',[Output_Variable Ext_t],'Orientation','down','ShowName','off','BackgroundColor',['[' num2str(Color_box) ']']);            
        case 'V_IN_giu'
            [Range_Block,~]=GET_RANGE_AND_ORIENTATION(Points-5*1i);
            add_block('built-in/To Workspace',[SLX.Name '/To_Work' num2str(Ramo.Nr_Ramo) Nr_box],'position',Range_Block,'VariableName',[Input_Variable Ext_t],'Orientation','up','ShowName','off','BackgroundColor',['[' num2str(Color_box) ']'],'MaxDataPoints','10000','SampleTime','Ts');            
        case 'V_OUT_su'
            [Range_Block,~]=GET_RANGE_AND_ORIENTATION(Points+5*1i);
            add_block('built-in/Constant',[SLX.Name '/Constant' num2str(Ramo.Nr_Ramo) Nr_box],'position',Range_Block,'Value',Output_Variable,'Orientation','up','ShowName','off','BackgroundColor',['[' num2str(Color_box) ']']);            
    end  % nulla : dot, tratteggio, NrR_snt, V_In_snt_su, Kn_in_M, V_Out_snt_giu  
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function         Punti=GET_POINTS_VECTORS(Points)       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Punti=zeros(length(Points),2);
for ii=1:length(Points)
    Punti(ii,1)=round(real(Points(ii)));
    Punti(ii,2)=round(imag(Points(ii)));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function         Points=CONVERT_POINTS(Punti)       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
X0=0;           % Converte punti POG in coordinate SLX
Y0=2.0;
Expand=20;      % Fattore di espansione nel passaggio POG -> SLX
Punti_x=round(Expand*(real(Punti)-X0)+120);     % Si arrotonda all'intero 
Punti_y=round(Expand*(Y0-imag(Punti))+50);      % Si arrotonda all'intero
Points=Punti_x+1i*Punti_y;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function         [Range_Block, Orientation]=GET_RANGE_AND_ORIENTATION(Points)       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Points_x=real(Points);
Points_y=imag(Points);
Range_Block=[min(Points_x) min(Points_y) max(Points_x) max(Points_y)];
Delta=Points(4)-Points(1);
angolo=round(atan2(imag(Delta),real(Delta))*180/pi);
switch angolo
    case 0
        Orientation='right';
    case {90 -270}
        Orientation='down';
    case {180 -180}
        Orientation='left';
    case {270 -90}
        Orientation='up';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function    [Range_Block, Orientation, Inputs]=GET_PIU_RANGE_AND_ORIENTATION(Points)       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Points_x=real(Points);
Points_y=imag(Points);
Range_Block=[min(Points_x) min(Points_y) max(Points_x) max(Points_y)];
% Delta=Points(end)-mean(Points(1:end-1));
Delta=Points(1)-mean(Points);
angolo=90*round(atan2(imag(Delta),real(Delta))*2/pi);
Rotazione=angle((Points(2)--mean(Points))/(Points(1)--mean(Points)));
switch angolo
    case 0
        Orientation='right';
        if Rotazione>0
            Inputs='-+|';
        else
            Inputs='|+-';
        end        
    case {270 -90}
        Orientation='up';
        Inputs='+|-';
    case {180 -180}
        Orientation='left';
        if Rotazione>0
            Inputs='|++';
        else
            Inputs='++|';
        end
    case {90 -270}
        Orientation='down';
        Inputs='+|-';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function        Punti=GET_PUNTI_PIU(Dir)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Punti=0.5*Dir*exp((0:0.02:1)*2*pi*1i);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Sistema = SIMULA_LO_SCHEMA_SIMULINK(Sistema)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SLX_Name=Sistema.SLX.Name;
load_system([Sistema.Dir_out Sistema.SLX.Name])
%%%%%%%%% Calcolo dei valori numerici dei parametri 
Parametri=Sistema.Parametri;
for ii=1:length(Parametri)
    switch Parametri(ii).Type
        case {'Kn0','Qn0','U0'}
            eval([Parametri(ii).Nome '=' num2str(Parametri(ii).Value) ';'])
    end
end
Tfin=num2str(Sistema.POG_SYS.sim_Tfin);                         % Durata della simulazione: Tfin=10;
Nr_Ts_Points=num2str(Sistema.POG_SYS.sim_Nr_Ts_Points);         % Numero di punti: Nr_Ts_Points='2000';
Ts=[Tfin '/' Nr_Ts_Points];
set_param(SLX_Name,'Solver','ode45','stoptime',Tfin,'MaxStep',Ts,'LimitDataPoints','off')
save_system(SLX_Name)
Out_Sim=sim(SLX_Name,'SrcWorkspace','current');
close_system(SLX_Name)
%%%%%%%%%%%%%%%%%%%%
if Sistema.Grafico.Nr_Figura==0
    figure(Sistema.Nr_Schema+200)
else
    figure(Sistema.Grafico.Nr_Figura+200)
end
clf; hold on; zoom on
%%%%%%%%%%%%%%%%%%%%
Variables=Out_Sim.get;
Variables=setdiff(Variables,'tout');
Nr_Var=length(Variables);
t=Out_Sim.get('tout');
for ii=1:Nr_Var
    y=Out_Sim.get(Variables{ii});
    subplot(Nr_Var,1,ii)
    plot(t,y)
    grid on 
    ylabel(strrep(Variables{ii},'_','\_'))
    if ii==1
        title(['Simulation of file: ' strrep(Sistema.Grafico.Nome_del_grafico,'_','\_')])
    end
    if ii==Nr_Var
        xlabel('Time [s]')
    end
end
if strcmp(Sistema.POG_SYS.sim_Print_SIM,'Si')
    PRINT_FIGURA([Sistema.Grafico.Dir_out Sistema.Grafico.Nome_del_grafico],Sistema.POG_SYS.pog_Graphic_Type,'_SIM')
end
Sistema.Out_Sim=Out_Sim;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [Par_Val, Par_Str, Par_Typ] = GET_PARAMETERS_VALUES(Sistema)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Par_Val=[];
Par_Str='';
Par_Typ='';
Ext_t='';                           % Ext_t='_t'; Added extension in the Input/Output Simulink blocks
for ii=1:Sistema.Nr_dei_Rami
    Ramo_ii=Sistema.Lista_Rami(ii);
    Str_Nr_Ramo=[ num2str(ii) '. '];
    Tipo_di_Ramo=Ramo_ii.Tipo_di_Ramo;
    [Output_Variable, Input_Variable, ~]=GET_COLOR_OF_OUTPUT_VARIABLE(Ramo_ii);
    switch Tipo_di_Ramo
        case 'Ingresso'
            if isempty(Ramo_ii.TR_o_GY)     % Se il blocco � un vero ingresso ...
                eval(['Par_Val.' Output_Variable '='''';'])
                eval(['Par_Str.' Output_Variable '=''' Str_Nr_Ramo GET_OUT_MEANING(Ramo_ii) '. Input variable. ' ''';'])
                eval(['Par_Typ.' Output_Variable '=''U'';'])
                %
                eval(['Par_Val.' Output_Variable Ext_t '=' Ramo_ii.POG.pog_In_0 ';'])
                eval(['Par_Str.' Output_Variable Ext_t '=''' Str_Nr_Ramo GET_OUT_MEANING(Ramo_ii) '. Input value. ' ''';'])
                eval(['Par_Typ.' Output_Variable Ext_t '=''U0'';'])
                %
                eval(['Par_Val.' Input_Variable '='''';'])
                eval(['Par_Str.' Input_Variable '=''' Str_Nr_Ramo GET_IN_MEANING(Ramo_ii) '. Input variable. ' ''';'])
                eval(['Par_Typ.' Input_Variable '=''Y'';'])
            else                    % Se il blocco � un trasformatore o un giratore  ...
                eval(['Par_Val.' char(Ramo_ii.K_name) '=' Ramo_ii.POG.pog_Kn_0 ';'])
                eval(['Par_Str.' char(Ramo_ii.K_name) '=''' Str_Nr_Ramo Ramo_ii.K_Str '. Transformer/Gyrator. ' ''';'])
                eval(['Par_Typ.' char(Ramo_ii.K_name) '=''Kn0'';'])
            end
        case 'Dinamico'     % Nel caso di blocchi dinamici ...
            eval(['Par_Val.' char(Ramo_ii.K_name) '=' Ramo_ii.POG.pog_Kn_0 ';'])
            eval(['Par_Str.' char(Ramo_ii.K_name) '=''' Str_Nr_Ramo Ramo_ii.K_Str '. Internal parameter. ' ''';'])
            eval(['Par_Typ.' char(Ramo_ii.K_name) '=''Kn0'';'])
            %
            eval(['Par_Val.' Ramo_ii.Q_name '='''';'])
            eval(['Par_Str.' Ramo_ii.Q_name '=''' Str_Nr_Ramo Ramo_ii.Q_Str '. Energy variable. ' ''';'])
            eval(['Par_Typ.' Ramo_ii.Q_name '=''Q'';'])
            %
            eval(['Par_Val.' Ramo_ii.Q_name '_0=' Ramo_ii.POG.pog_Qn_0 ';'])
            eval(['Par_Str.' Ramo_ii.Q_name '_0=''' Str_Nr_Ramo Ramo_ii.Q_Str '. Initial condition. ' ''';'])
            eval(['Par_Typ.' Ramo_ii.Q_name '_0=''Qn0'';'])
            %
            eval(['Par_Val.' Output_Variable '='''';'])
            eval(['Par_Str.' Output_Variable '=''' Str_Nr_Ramo GET_OUT_MEANING(Ramo_ii) '. State variable. ' ''';'])
            eval(['Par_Typ.' Output_Variable '=''X'';'])
            %
            eval(['Par_Val.' Output_Variable '_0='''';'])
            eval(['Par_Str.' Output_Variable '_0=''' Str_Nr_Ramo GET_OUT_MEANING(Ramo_ii) '. Initial condition. ' ''';'])
            eval(['Par_Typ.' Output_Variable '_0=''X0'';'])
       case 'Resistivo'     % Nel caso di blocchi dissipativi ...
            eval(['Par_Val.' char(Ramo_ii.K_name) ' = ' Ramo_ii.POG.pog_Kn_0 ';'])
            eval(['Par_Str.' char(Ramo_ii.K_name) ' = ''' Str_Nr_Ramo Ramo_ii.K_Str '. Internal parameter. ' ''';'])
            eval(['Par_Typ.' char(Ramo_ii.K_name) '=''Kn0'';'])
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Meaning = GET_OUT_MEANING(Ramo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Ramo.Out,'Flow')
    Meaning = Ramo.F_Str;
elseif strcmp(Ramo.Out,'Effort')
    Meaning = Ramo.E_Str;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  Meaning = GET_IN_MEANING(Ramo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Ramo.Out,'Flow')
    Meaning = Ramo.E_Str;
elseif strcmp(Ramo.Out,'Effort')
    Meaning = Ramo.F_Str;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%  Possibili valori per le seguenti variabili:
% 'Tipo_di_Ramo'    =   {'Filo', 'Ingresso', 'Dinamico', 'Resistivo'}       
% 'SP'              =   {'Foglia', 'Serie', 'Parallelo'}       

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ** 26 **: Introdotte le funzioni PERCORSO_EFFORT e Percorso Flow.
% ** 27 **: Introdotte le funzioni NESTED_EFFORT e NESTED_FLOW ed eliminato Percorso.
% ** 28 **: Le funzioni NESTED_EFFORT e NESTED_FLOW sono state semplificate
% ** 29 **: L'orientamento dello schema � stato migliorato sensibilmente
% ** 30 **: Nuova e piu' semplice versione di NESTED_EFFORT. 
% ** 31 **: Nuova e piu' semplice versione di NESTED_FLOW. Doppio controllo attivo. 
% ** 32 **: Nuova e piu' efficace modo di verificare lo schema: 'E'-in-parallelo; 'F'-in-serie 
% ** 33 **: Sistemi senza dissipazione: corretto errore. I nomi fanno riferimento al nr del ramo.  
% ** 34 **: Sistemi senza ingressi: corretto errore. Inserita analisi Serie/Parallelo: 
%           functions "Crea_lo_Schema_POG" ("SHOW_SCHEMA_A_BLOCCHI_POG") + "RIDUCI_SERIE_PARALLELO".  
% ** 35 **: Versione intermedia di lavoro 
% ** 36 **: E' possibile togliere i corto circuiti. Schema POG non ancora a posto
% ** 37 **: Sono stati introdotti: i parametri 'Doppi' e 'Show_Polarita'.
% ** 38 **: Sono stati introdotti: "Params_R" e "Params_S" (inserimento automatico dei parametri) 
% ** 39 **: Sono stati introdotti: "Params_B" la gestione automatica dei blocchi 
% ** 40 **: Sono stati introdotti: gli ingressi eU, mU, rU e iU; I trasformatori
%           (solo nel grafico); Verifica di consistenza; (Versione "sospesa")
% ** 41 **: E' stata introdotta la function "SOSTITUZIONE_DEI_METABLOCCHI"
% ** 41 **: Sono stati introdotti: i comandi ridervati 'Ge', 'II', 'T_G'; 
% ** 42 **  E' stata aggiunta la scatola agli elementi di connessione; I blocchi eV, eI, 
%           mF, mV, rW, rT, iP e iQ  sono gestiti come metablocchi. 
% ** 43 **  E' stata aggiunta la gestone dei blocchi trasformatori. 
% ** 44 **  E' stata aggiunta la gestone dei blocchi giratori. L'analisi funziona. 
% ** 45 **  Trasformatori: E2=K*E1. Giratori: F2=K*E1. 
% ** 46 **  Trasformatori: E1=K*E2. Giratori: E1=K*F2. Inserito il comando "Help"
% ** 47 **  Riduzione di sistema che abbiano elementi Inf nella matrice A
%           I comandi "Pn" e "Tcc" sono stati tolti. I Nodi sono stati riordinati
%           La funzione "Old" � stata ripristinata.
% ** 48 **  Inserito il calcolo delle Partizioni. Gestione di Input_POG vettoriale.
% ** 49 **  Il calcolo delle Partizioni � stato anticipato. 
% ** 50 **   
% ** 51 **  Aggiunta funzione CREA_HELP. Creato il file "POG.m"
% ** 52 **  (05/02/2017) (********) E' stata attivata la graficazione degli schemi POG.
%           Nuove funzioni: SVILUPPA_SERIE_PARALLELO, CALCOLA_STR_TYPE, CALCOLA_POSIZIONE_BLOCCI, 
%           CALCOLA_DIMENSIONE_BLOCCI, SHAPE_DRAW_1, SHAPE_DRAW_2, ecc.
% ** 53 **  (08/03/2017) La graficazione degli schemi POG pu� andare a capo. Through a Across variables  
% ** 55 **  (17/05/2017) Help in Inglese. Attivato il blocco "BC, [1; A], [2; B], Kn, F1=K1*F2".   
% ** 56 **  (25/05/2017) Ai parametri di ingresso � associata una tipologia, dei limiti e/o dei valori possibili.   
%           Creata la funzione STAMPA_CSV che spampa le informazioni su titti i parametri. Inserito "LEGGI_DA_FILE"   
% ** 57 **  (30/05/2017) Modificate le scritte Help and Help_ENG. Inserita function STAMPA_CSV.
% ** 59 **  (15/06/2017) Cambiata la struttura dei file Parms_Rami e Parms_Sistemi
% ** 60 **  (xx/06/2017) 
% ** 61 **  (xx/08/2017) I nomi di default ora utilizzano come il numero di blocchi "emri"  
%           Sono stati messi a posto le scritte relative a trasformatori e giratori.
%           E' stata corretta la funzione SWAP_POG. E' possibile eseguire split multipli.
%           Usare "pSplit,-1" per avere indicazioni su dove spezzare lo schema a blocchi
%           Esegue anche lo split dello schema fisico (Split,3/5). Ho tolto
%           il diary. Fa lo zip di titti i file nel diretorio out.

% Analizza_il_Sistema('C:\Users\roberto\Documents\POG\Sistemi_POG\media\user_admin\Alt\Alternanza_R_C.txt')
% Sistema=Analizza_il_Sistema('C:\Users\roberto\Documents\POG\Sistemi_POG\media\user_admin\Alt\Alternanza_R_C.txt');
% Sistema=Analizza_il_Sistema('C:\Users\roberto\Documents\POG\Sistemi_POG\media\user_admin\Alt\Kers.txt');
% Sistema=Analizza_il_Sistema('C:\Users\roberto\Documents\POG\Sistemi_POG\media\user_admin\Kers\Kers.txt');
