*** Settings ***
Documentation       Search Samsung phones, filtered Nike shoes, and Afnan perfume specifications on Flipkart.
Library             Browser    auto_closing_level=KEEP
Library             String
Test Teardown       Close Browser After Delay

*** Variables ***
${FLIPKART}         https://www.flipkart.com/
${SEARCH_TERM}      s26
${NIKE_SEARCH_TERM}    nike+men+shoes
${PERFUME_SEARCH_TERM}    perfume
${HEADLESS}         ${FALSE}
${LOGIN_CLOSE}      css=span[role="button"]:has-text("✕")
@{DETAIL_SECTIONS}  Showcase    Specifications    Warranty    Manufacturer info

*** Keywords ***
Open Flipkart Search
    [Arguments]    ${search_term}    ${expected_text}
    New Browser    chromium    headless=${HEADLESS}
    New Context
    New Page    ${FLIPKART}search?q=${search_term}    wait_until=domcontentloaded
    Dismiss Login If Present
    Wait For Elements State    text=${expected_text} >> nth=0    visible    timeout=30s

Dismiss Login If Present
    FOR    ${attempt}    IN RANGE    5
        ${count}=    Get Element Count    ${LOGIN_CLOSE}
        IF    ${count} == 0
            RETURN
        END
        ${states}=    Get Element States    ${LOGIN_CLOSE}
        IF    "visible" in $states
            Click    ${LOGIN_CLOSE}
            Wait For Elements State    ${LOGIN_CLOSE}    hidden    timeout=5s
        ELSE
            RETURN
        END
    END
    ${states}=    Get Element States    ${LOGIN_CLOSE}
    IF    "visible" in $states
        Fail    Flipkart login popup kept reopening after five close attempts.
    END

Close Browser After Delay
    Sleep    10 seconds
    Close Browser

Select Checkbox Filter
    [Arguments]    ${option}    ${facet}
    ${filter}=    Set Variable    xpath=//label[.//input[@type='checkbox'] and normalize-space(.)='${option}']
    Wait For Elements State    ${filter}    stable    timeout=10s
    Click    ${filter}
    Wait For Condition    Url    contains    ${facet}    timeout=30s

Select Rating Filter
    Click    text="4★ & above"
    Wait For Condition    Url    contains    facets.rating    timeout=30s

Search And Select Brand Filter
    [Arguments]    ${brand}
    Click    text="Brand"
    Fill Text    css=input[placeholder="Search Brand"]    ${brand}
    ${brand_option}=    Convert To Upper Case    ${brand}
    Wait For Elements State    text="${brand_option}"    visible    timeout=10s
    Click    text="${brand_option}"
    Wait For Condition    Url    contains    facets.brand    timeout=30s

Get Active Filters
    ${filters}=    Evaluate JavaScript    ${None}    () => new URL(location.href).searchParams.getAll("p[]").map(value => decodeURIComponent(value.replaceAll("+", " ")))
    RETURN    ${filters}

Active Filters Should Contain
    [Arguments]    @{expected_filters}
    ${active_filters}=    Get Active Filters
    FOR    ${expected_filter}    IN    @{expected_filters}
        Should Contain    ${active_filters}    ${expected_filter}
    END

Open Product Link
    [Arguments]    ${product_locator}
    Wait For Elements State    ${product_locator}    visible    timeout=15s
    ${product_name}=    Get Text    ${product_locator}
    ${product_url}=    Evaluate JavaScript    ${product_locator}    element => element.href
    Log To Console    Opening product: ${product_name}
    ${pages_before}=    Get Page IDs
    Click    ${product_locator}
    ${pages_after}=    Get Page IDs
    IF    len($pages_after) > len($pages_before)
        Switch Page    NEW
    END
    ${current_url}=    Get Url
    IF    "/p/" not in $current_url
        Go To    ${product_url}    wait_until=domcontentloaded
    END
    Wait For Condition    Url    contains    /p/    timeout=30s

Open First S26 Result
    ${result}=    Set Variable    css=a:has-text("Samsung Galaxy S26 5G") >> nth=0
    Wait For Elements State    ${result}    visible    timeout=30s
    ${pages_before}=    Get Page IDs
    Click    ${result}
    Sleep    2 seconds
    ${pages_after}=    Get Page IDs
    IF    len($pages_after) > len($pages_before)
        Switch Page    NEW
    END
    Dismiss Login If Present

Inspect Product Details
    ${page_text}=    Get Text    body
    Should Contain    ${page_text}    Samsung Galaxy S26
    ${url}=    Get Url
    Should Contain    ${url}    /p/
    ${highlights}=    Get Lines Matching Regexp    ${page_text}    (?i)Samsung Galaxy S26|[0-9]+ GB RAM|[0-9]+([.][0-9]+)? inch.*Display|[0-9]+MP.*Camera|[0-9]+ mAh.*Battery|[0-9]+ Year Manufacturer Warranty|₹[0-9,]+
    Log To Console    Product: ${highlights}
    ${show_more}=    Get Element Count    text="Show More"
    IF    ${show_more} > 0
        Click    text="Show More"
    END
    FOR    ${section}    IN    @{DETAIL_SECTIONS}
        Click Product Detail Section    ${section}
        Dismiss Login If Present
        ${content}=    Get Text    body
        ${details}=    Get Lines Matching Regexp    ${content}    (?i)${section}|Brand|Model Name|Model Number|Manufacturer|Warranty|RAM|Internal Storage|Display|Camera|Battery|Processor|₹[0-9,]+|[0-9]+ GB
        Log To Console    ${section}: ${details}
    END

Click Product Detail Section
    [Arguments]    ${section}
    ${section_locator}=    Set Variable    text="${section}"
    Wait For Elements State    ${section_locator}    visible    timeout=15s
    Evaluate JavaScript    ${section_locator}    element => element.click()
    Sleep    1 second

*** Test Cases ***
Flipkart Search S26
    [Documentation]    Opens the first Samsung S26 listing and checks its product detail sections.
    [Tags]    smoke    flipkart    browser
    [Timeout]    2 minutes
    [Setup]    Open Flipkart Search    ${SEARCH_TERM}    Samsung Galaxy S26
    Open First S26 Result
    Inspect Product Details

Flipkart Filter Nike Men's Shoes
    [Documentation]    Filters Nike men's shoes, sorts by popularity, and opens the top result.
    [Tags]    smoke    flipkart    browser
    [Timeout]    2 minutes
    [Setup]    Open Flipkart Search    ${NIKE_SEARCH_TERM}    Nike
    Click    text="11 MORE"
    Select Checkbox Filter    7    facets.size
    Click    text="Color"
    Wait For Elements State    text="Black"    visible    timeout=10s
    Select Checkbox Filter    Black    facets.color
    Select Rating Filter
    Active Filters Should Contain
    ...    facets.size[]=7
    ...    facets.color[]=Black
    ...    facets.rating[]=4★ & above
    Click    text="Popularity"
    Wait For Condition    Url    contains    sort=popularity    timeout=30s
    ${sorted_url}=    Get Url
    Should Contain    ${sorted_url}    sort=popularity
    ${top_product_url}=    Evaluate JavaScript    ${None}    () => [...document.querySelectorAll('a[href*="/p/"]')].find(link => link.innerText.trim() && link.getClientRects().length)?.href
    Should Not Be Empty    ${top_product_url}
    Log To Console    Most popular filtered Nike result: ${top_product_url}
    Go To    ${top_product_url}    wait_until=domcontentloaded
    ${product_url}=    Get Url
    Should Contain    ${product_url}    /p/
    ${product_details}=    Get Text    body
    Should Contain    ${product_details}    NIKE

Flipkart Search Afnan Perfume
    [Documentation]    Finds Afnan Supremacy perfume rated above 4 for men.
    [Tags]    smoke    flipkart    browser
    [Timeout]    3 minutes
    [Setup]    Open Flipkart Search    ${PERFUME_SEARCH_TERM}    Perfume
    Select Rating Filter
    Search And Select Brand Filter    Afnan
    Click    text="Gender"
    Select Checkbox Filter    Men    facets.ideal_for
    Active Filters Should Contain
    ...    facets.rating[]=4★ & above
    ...    facets.brand[]=AFNAN
    ...    facets.ideal_for[]=Men
    ${supremacy_result}=    Set Variable    xpath=(//a[contains(@href, '/p/') and contains(translate(., 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'supremacy') and contains(translate(., 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'collector')])[1]
    Open Product Link    ${supremacy_result}
    ${product_url}=    Get Url
    Should Contain    ${product_url}    /p/
    ${product_details}=    Get Text    body
    Should Contain    ${product_details}    AFNAN
    Should Contain    ${product_details}    Supremacy
    Should Contain    ${product_details}    Collector
    ${all_details_dropdown}=    Set Variable    xpath=//div[@tabindex='0'][.//*[normalize-space(text())='All details']]
    Wait For Elements State    ${all_details_dropdown}    visible    timeout=15s
    Click    text="All details"
    Wait For Elements State    text="Description"    visible    timeout=15s
    ${specifications}=    Set Variable    ${EMPTY}
    FOR    ${tab}    IN    Specifications    Description    Manufacturer info
        ${tab_locator}=    Set Variable    text="${tab}"
        Wait For Elements State    ${tab_locator}    visible    timeout=15s
        Evaluate JavaScript    ${tab_locator}    element => element.parentElement.click()
        ${tab_selected}=    Evaluate JavaScript    ${tab_locator}    element => getComputedStyle(element.parentElement).backgroundColor === 'rgb(31, 31, 31)'
        Should Be True    ${tab_selected}    ${tab} tab did not become selected
        ${tab_content}=    Get Text    body
        Should Contain    ${tab_content}    ${tab}
        IF    $tab == 'Specifications'
            ${specifications}=    Set Variable    ${tab_content}
        END
        Log To Console    Selected ${tab} tab.
    END
    Should Contain    ${specifications}    Specifications
    Should Contain    ${specifications}    Supremacy Collector's Edition
    Should Contain    ${specifications}    Fragrance Classification
    Should Contain    ${specifications}    Eau de Parfum
    Should Contain    ${specifications}    Ideal For
    Should Contain    ${specifications}    Men
    Should Contain    ${specifications}    Quantity
    Should Contain    ${specifications}    100 ml
    Log To Console    Afnan Supremacy specifications: ${specifications}
