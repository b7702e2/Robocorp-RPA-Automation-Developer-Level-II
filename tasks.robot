*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Archive
Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.PDF
Library    RPA.Tables

*** Variables ***
${XPATH_TO_ORDER_YOUR_ROBOTS_BUTTOM}    //*[@id="root"]/header/div/ul/li[2]/a
${XPATH_TO_OK_BUTTON}    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
${XPATH_TO_HEAD}    //*[@id="head"]
${XPATH_TO_LEGS}    //*[@id="root"]/div/div[1]/div/div[1]/form/div[3]/input
${XPATH_TO_ADDRESS}    //*[@id="address"]
${XPATH_TO_ORDER_BUTTON}    //*[@id="order"]
${XPATH_TO_ORDER_ANOTHER_ROBOT}    //*[@id="order-another"]
${XPATH_TO_RECEIPT_TITLE}    //*[@id="receipt"]/h3
${XPATH_TO_RECEIPT}    //*[@id="receipt"]
${XPATH_TO_PREVIEW_BUTTON}    //*[@id="preview"]
${XPATH_TO_PREVIEW_IMAGE}    //*[@id="robot-preview-image"]

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/
    Wait Until Element Is Visible    ${XPATH_TO_ORDER_YOUR_ROBOTS_BUTTOM}    timeout=10
    Click Element    ${XPATH_TO_ORDER_YOUR_ROBOTS_BUTTOM}
    Wait Until Element Is Visible    ${XPATH_TO_OK_BUTTON}    timeout=10
    Click Element    ${XPATH_TO_OK_BUTTON}

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=${True}
    ${orders}=    Read table from CSV    path=orders.csv
    [return]    ${orders}

Fill the form
    [Arguments]    ${head}    ${body}    ${legs}    ${address}
    Select From List By Index    ${XPATH_TO_HEAD}    ${head}
    Select Radio Button    group_name=body    value=${body}
    Input Text    ${XPATH_TO_LEGS}    ${legs}
    Input Text    ${XPATH_TO_ADDRESS}    ${address}

Preview the robot
    Click Element    ${XPATH_TO_PREVIEW_BUTTON}

Store the receipt as a PDF file
    [Arguments]    ${name}
    Wait Until Element Is Visible    ${XPATH_TO_RECEIPT}
    ${receipt_html}=    Get Element Attribute    ${XPATH_TO_RECEIPT}    outerHTML
    ${full_filename}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}receipt_for_order_number${name}.pdf
    Html To Pdf    ${receipt_html}    ${full_filename}
    [Return]    ${full_filename}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${screenshot}=    Capture Element Screenshot
    ...    ${XPATH_TO_PREVIEW_IMAGE}
    ...    filename=${OUTPUT_DIR}${/}screenshots${/}robot_preview_from_order${order_number}.png
    [return]    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${screenshots}=    Create List    ${screenshot}
    Add Files To Pdf    ${screenshots}    ${pdf}    append=${True}
    Close Pdf    ${pdf}

Submit the order
    Click Element    ${XPATH_TO_ORDER_BUTTON}
    Wait Until Element Is Visible    ${XPATH_TO_RECEIPT_TITLE}    timeout=0.1

Order another robot
    Click Element    ${XPATH_TO_ORDER_ANOTHER_ROBOT}
    Wait Until Element Is Visible    ${XPATH_TO_OK_BUTTON}    timeout=10
    Click Element    ${XPATH_TO_OK_BUTTON}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Fill the form    ${order}[Head]    ${order}[Body]    ${order}[Legs]    ${order}[Address]
        Preview the robot
        Wait Until Keyword Succeeds    10x    0.5 sec    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Order another robot
    END
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}receipts.zip