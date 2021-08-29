# +
*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Excel.Files
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Database
Library           RPA.FileSystem
Library           RPA.Archive
Library           RPA.Robocloud.Secrets
Library           RPA.Dialogs

# -


*** Keywords ***
Get and log the value of the vault secrets using the Get Secret keyword
    ${secret}=    Get Secret    credentials
    # Note: in real robots, you should not print secrets to the log. this is just for demonstration purposes :)
    Log             ${secret}[username]
    Log             ${secret}[password]
    #${get_URL}=     ${secret}[URL]

*** Keywords ***
Open the website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    #Wait Until Page Contains Element    id:OK
    Click Button    OK

*** Keywords ***
Choose orders.csv file from user local directory
    Add heading    Upload CSV File
    Add file input
    ...    label=Please select the orders.csv file (from folder local_files)
    ...    name=fileupload
    ...    file_type=CSV files (*.csv)
    ...    destination=${CURDIR}${/}csv_folder
    ${response}=    Run dialog
    [Return]    ${response.fileupload}[0]

*** Keywords ***
Loop working
    [Arguments]    ${excel_file_path}
    
    FOR     ${file_row}     IN RANGE     0  20
        ${table}=    Read table from CSV    ${excel_file_path}
        Log   Found columns: ${table.columns}
    
        #Fill the form with data from .csv file
        ${file_head}=       RPA.Tables.Get Table Cell    ${table}    ${file_row}    ${1}
        ${file_body}=       RPA.Tables.Get Table Cell    ${table}    ${file_row}    ${2}
        ${file_legs}=       RPA.Tables.Get Table Cell    ${table}    ${file_row}    ${3}
        ${file_address}=    RPA.Tables.Get Table Cell    ${table}    ${file_row}    ${4}
    
        RPA.Browser.Selenium.Input Text    id:address    ${file_address}
        Select From List By Index    id:head   ${file_head}
        RPA.Browser.Selenium.Click Element    id:id-body-${file_body}
        RPA.Browser.Selenium.Input Text    css:input[placeholder="Enter the part number for the legs"]    ${file_legs}
    
        #Choose Preview button
        Click Button    id:preview
        Wait Until Page Contains Element    id:robot-preview-image
    
        #Choose Order button
        Click Button    id:order
        
        #Send query and keep checking until success
        Checking
        
        #Store the order receipt as a PDF file   
        ${PDF_file_html}=    Get Element Attribute    id:receipt    outerHTML
        Html To Pdf    ${PDF_file_html}    ${CURDIR}${/}output${/}PDF_receipt_${file_row}.pdf
          
        #Take a screenshot
        Screenshot    id:receipt    ${CURDIR}${/}output${/}screenshot_receipt_${file_row}.png
        
        Sleep   1s
        #Open the PDF file
        Open Pdf   ${CURDIR}${/}output${/}PDF_receipt_${file_row}.pdf
        
        #Add screenshot to the corresponding PDF file
        Add Watermark Image To Pdf
        ...     image_path=${CURDIR}${/}output${/}screenshot_receipt_${file_row}.png    
        ...     source_path=${CURDIR}${/}output${/}PDF_receipt_${file_row}.pdf   
        ...     output_path=${CURDIR}${/}output${/}Final_PDF_receipt_${file_row}.pdf
        
        #Close the PDF file
        Close Pdf   ${CURDIR}${/}output${/}PDF_receipt_${file_row}.pdf
        
        #Order another robot
        Sleep   1s
        Click Button    id:order-another
        Sleep   1s
        Click Button    OK
    END

*** Keywords ***
Click button Order again
     Click Button    id:order

*** Keywords ***
Checking
    Wait Until Keyword Succeeds     3x   500ms  repeat

*** Keywords ***
repeat
    ${MAX_TRIES} =   Set variable   3
    FOR      ${i}    IN RANGE    ${MAX_TRIES}
        ${CONDITION}=       Does Page Contain Element    id:receipt
        Log   CONDITION value is ${CONDITION}
        ${res} =   Set variable   True
        IF      ${CONDITION} != ${res}
            Sleep   1s
            Click Button    id:order
            Sleep   1s
        ELSE
            Log To Console    Okay.
        END
    END

*** Keywords ***
Create a ZIP file of the folder that contains all receipts
    Archive Folder With Zip  ${CURDIR}${/}output  all_receipts.zip


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Get and log the value of the vault secrets using the Get Secret keyword
    ${excel_file_path}=    Choose orders.csv file from user local directory
    Open the website
    Loop working    ${excel_file_path}
    Create a ZIP file of the folder that contains all receipts
    Log  Done.
