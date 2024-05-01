# BwE NOR Validator v1.31
![BwE](https://i.imgur.com/GsR281J.jpeg)

After 11 years the source code for the original and greatest PS3 NOR Validator has been released!

This is version 1.31 and was the last version made.    

    BwE NOR Validator - HTML Output Edition.
    
    Created/Started by BwE on the 14th November 2012 (Because I was too lazy to constantly check everything).
    
    Greetz/Credit: EussNL, Judges, No0bZiLLa, Rogero, Rebug, deank, 3absiso, AFP, SCE & PS3 Dev Wiki (+ Its Contributers).
    
    =====================================================================================================================
    
    This all in one validator/patcher will interpret the byte orientation, patch for 3.55/4.40 and will then output the results of 2800+ validations via HTML.
    
    =====================================================================================================================
    
    How?
    
    1 - Place your .bin/s in the same folder as the validator.
    2 - Run the validator and press Start.
    3 - A console will appear asking you to select your dump (if you have more than one in the folder).
    4 - Make your selection and or select if you watch to patch it (either in its current byte orientation or the opposite).
    5 - Wait patiently.
    6 - Press Enter at the end to launch the output.
    
    =====================================================================================================================
    
    Explanation
    
    After selecting your dump and choosing which patch you want it will begin to process the validation. Once it is finished it will give you a brief count of the results, after this you simply press enter to exit.
    
    The program will then open a html output illustrating everything that has been validated. Scroll through or use the menu at the top and read each section.
    
    If a validation says 'warning' or 'danger' investigate it yourself manually using a hex editor, or contact somebody knowledgeable. Only corruption messages will show you the exact offset to look at, everything else won't so this is where you have to read/learn about it on the ps3devwiki.
    
    Some validations will tell you that you need to patch it, if this is the case then do so and re-validate the patched dump.
    
    If your dump has any 'danger' messages in the per console sections (find them in the menu) then there is a good chance its completely ruined and unfixable. Also, if your dump has a large amount of 'danger' messages then there is a serious issue - bad wiring can be discovered if you have any repetition in the dump. 
    
    =====================================================================================================================
    
    Areas Of Validation
    
     * Statistics
     * First Region Header
     * Flash Format
     * Flash Region
     * Asecure_Loader/Metldr
     * Asecure_Loader/Metldr Corrupt Sequences
     * Asecure_Loader/Metldr Encrypted Statistics/Entropy
     * EID
     * EID0
     * EID1
     * EID2
     * EID3
     * EID4
     * EID5
     * IDPS
     * CISD
     * CISD0
     * CISD1
     * CISD2
     * CCSD
     * CCSD0
     * TRVK_PRG0
     * TRVK_PRG1
     * TRVK_PKG0
     * TRVK_PKG1
     * ROS0
     * ROS1
     * ROS0/1 AuthID's/MD5's
     * Revoke/CoreOS MD5's
     * CVTRM/VTRM0
     * VTRM 1
     * Second Region Header
     * Second Region Block 0
     * Second Region Block 1
     * CELL_EXTNOR_AREA
     * Lv0ldr/Bootldr
     * Lv0ldr/Bootldr Corrupt Sequences
     * Lv0ldr/Bootldr Statistics/Entropy
     * Minimum Version
     * File Digest Keys
     * PerConsole Nonce
     * Corrupt Sequences
     * Repetition
     * Authenticiation IDs
    
    =====================================================================================================================
    
    Changelog
    
    1.31 - 27/05/2013 : added eid4 + fixed bug in entropy (note: possibly final version, unless adding firmware revisions/new consoles)
    1.30 - 21/05/2013 : completely rewritten eid, cisd, ccsd + added more validations to it, upgraded other minor validations. all due to upcoming nand validator
    1.28 - 15/05/2013 : completely rewritten cvtrm validation + added more validations to it, upgraded/perfected entropy 
    1.25 - 13/05/2013 : added entropy check for metldr/bootldr 
    1.24 - 06/05/2013 : added more information to suit newly discovered ps3 data, improved validation, added a tip for bad md5's, removed version forcing
    1.23 - 29/04/2013 : improved validation, added 4.41 ofw information
    1.22 - 16/04/2013 : added 115 more validations + changed statistic range for bootldr + other small boring changes
    1.21 - 11/04/2013 : patch3 error fix.
    1.20 - 10/04/2013 : added new console data, removed 3.56 patch (replaced with 4.40), added protection against using old validator, changed corruption check (again!), added quick info for console.
    1.19 - 09/04/2013 : changed metldr statistic range, minver check (to suit refurbished ps3s), corruption changes
    1.18 - 08/04/2013 : upgraded cisd/cell_ext_nor_area/metldr validations to suit unique metldr.2 revision, changed corruption output (again).
    1.17 - 08/04/2013 : changed repetition check, changed corruption output, bugfix
    1.16 - 02/04/2013 : added rogero's 4.40 patch, changed options, added 25+ md5's, changed stats range and id check
    1.15 - 25/03/2013 : added 4.40 ofw information and optimised some code
    1.14 - 19/03/2013 : improved validation of the flash-region table
    1.13 - 18/03/2013 : better handling for metldr.2, more id detections and md5s, added byte reversal option for experimenting with E3
    1.12 - 16/03/2013 : md5 bug fix, changed id detections and general improvements
    1.11 - 08/03/2013 : improved patching structure, added 3 musketeers patch (3.56 patching), code optimization
    1.10 - 04/03/2013 : added 25+ validations + changed results & outputs + bugfix
    1.09 - 02/03/2013 : improved corruption checks for metldr/bootldr + more validations + old coreos bug fix (again) + changed some results
    1.08 - 29/02/2013 : added timeout for version check + added 16bit corrupt sequence check + fixed long outputs + fixed metldr ident bug + changed some warning/danger results + changed 00/ff results
    1.06 - 27/02/2013 : fixed bug when handling old coreos versions + fixed .self md5 list
    1.05 - 25/02/2013 : added approx 220 more validations + changed statistic ranges + latest version check + fixes to metldr/bootldr
    1.02 - 22/02/2013 : more md5's & authid checks + changed some results.
    1.01 - 16/02/2013 : authid check bugfix
    1.00 - 15/02/2013 : first public release 
    
    =====================================================================================================================
    
    Use at own risk! Valid dumps may be invalid - Invalid dumps may be valid. 
    There are almost infinite variations of each dump! Have fun and good luck! 
    
    Report any bugs or issues to bwe@betterwayelectronics.com or directly to BwE @ irc.efnet.org #ps3downgrade or irc.ps3sanctuary.com #ps3hax
    
    
    Give credit if you are using this for other people!
    
    Made in Australia!
    
    =====================================================================================================================
    
    [ www.ps3devwiki.com / www.betterwayelectronics.com ]

