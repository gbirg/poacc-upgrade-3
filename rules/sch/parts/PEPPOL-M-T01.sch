<?xml version="1.0" encoding="UTF-8"?>    
    <schema xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:u="utils" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        schemaVersion="iso" queryBinding="xslt2">
        
        <title>Rules for PEPPOL BIS 3.0 Order</title>

        
        <ns uri="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" prefix="cbc"/>
        <ns uri="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" prefix="cac"/>
        <ns uri="urn:oasis:names:specification:ubl:schema:xsd:Order-2" prefix="ubl-order"/>
        <ns uri="http://www.w3.org/2001/XMLSchema" prefix="xs"/>
        <ns uri="utils" prefix="u"/>

        <xsl:key name="k_lineId"  match="cac:LineItem" use="cbc:ID"/>
        
        <!-- tag::functions[] -->
        <!-- Functions -->
        
        <function xmlns="http://www.w3.org/1999/XSL/Transform" name="u:slack" as="xs:boolean">
            <param name="exp" as="xs:decimal"/>
            <param name="val" as="xs:decimal"/>
            <param name="slack" as="xs:decimal"/>
            <value-of select="xs:decimal($exp + $slack) &gt;= $val and xs:decimal($exp - $slack) &lt;= $val"/>
        </function>
        
        <pattern>       
            
            <let name="documentCurrencyCode" value="/ubl-order:Order/cbc:DocumentCurrencyCode"/>
            <let name="sumLineExtensionAmount" value="if (/ubl-order:Order/cac:OrderLine/cac:LineItem/cbc:LineExtensionAmount) then xs:decimal(sum(/ubl-order:Order/cac:OrderLine/cac:LineItem/cbc:LineExtensionAmount)) else 0"/>
            <let name="sumAllowance" value="if (/ubl-order:Order/cac:AllowanceCharge[normalize-space(cbc:ChargeIndicator) = 'false']) then xs:decimal(sum(/ubl-order:Order/cac:AllowanceCharge[normalize-space(cbc:ChargeIndicator) = 'false']/cbc:Amount)) else 0"/>
            <let name="sumCharge" value="if (/ubl-order:Order/cac:AllowanceCharge[normalize-space(cbc:ChargeIndicator) = 'true']) then xs:decimal(sum(/ubl-order:Order/cac:AllowanceCharge[normalize-space(cbc:ChargeIndicator) = 'true']/cbc:Amount)) else 0"/>
            <let name="VATamount" value="if (/ubl-order:Order/cac:TaxTotal/cbc:TaxAmount) then xs:decimal(/ubl-order:Order/cac:TaxTotal/cbc:TaxAmount) else 0"></let>
            
       
          
            <!-- Amounts -->
            <rule context="cbc:Amount | cbc:TaxAmount | cbc:LineExtensionAmount | cbc:PriceAmount | cbc:BaseAmount | cac:AnticipatedMonetaryTotal/cbc:*">      
                <assert id="PEPPOL-T01-R003"
                    test="not(@currencyID) or @currencyID = $documentCurrencyCode"
                    flag="fatal">An order MUST be stated in a single currency</assert>
                <assert id="PEPPOL-T01-R028"
                    test="ancestor::node()/local-name() = 'Price' or string-length(substring-after(., '.')) &lt;= 2"
                    flag="fatal">Elements of data type amount cannot have more than 2 decimals (I.e. all amounts except unit price amounts)</assert>
            </rule>
            
            <!-- Document level -->          
            <rule context="ubl-order:Order">         
                <assert id="PEPPOL-T01-R002"
                    test="cac:ValidityPeriod/cbc:EndDate"    
                    flag="warning">An order SHOULD provide information about its validity end date.
                </assert>             
            </rule>
            
            <!-- Buyer party -->
            <rule context="cac:BuyerCustomerParty/cac:Party">
                <assert id="PEPPOL-T01-R014"
                    test="cac:PartyName/cbc:Name or cac:PartyIdentification/cbc:ID"
                    flag="fatal">An order MUST have the buyer party official name or a buyer party identifier</assert>
            </rule>
            
            <!-- Seller party -->
            <rule context="cac:SellerSupplierParty/cac:Party">
                <assert id="PEPPOL-T01-R015"
                    test="cac:PartyName/cbc:Name or cac:PartyIdentification/cbc:ID"
                    flag="fatal">An order MUST have the seller party official name or a seller party identifier</assert>
            </rule>
          
            <rule context="cac:PartyTaxScheme[cac:TaxScheme/cbc:ID='VAT']">
                <assert id="PEPPOL-T01-R026"
                    test="( contains( 'AD AE AF AG AI AL AM AN AO AQ AR AS AT AU AW AX AZ BA BB BD BE BF BG BH BI BL BJ BM BN BO BR BS BT BV BW BY BZ CA CC CD CF CG CH CI CK CL CM CN CO CR CU CV CX CY CZ DE DJ DK DM DO DZ EC EE EG EH EL ER ES ET FI FJ FK FM FO FR GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY HK HM HN HR HT HU ID IE IL IM IN IO IQ IR IS IT JE JM JO JP KE KG KH KI KM KN KP KR KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MF MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ NA NC NE NF NG NI NL NO NP NR NU NZ OM PA PE PF PG PH PK PL PM PN PR PS PT PW PY QA RO RS RU RW SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR ST SV SY SZ TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ UA UG UM US UY UZ VA VC VE VG VI VN VU WF WS YE YT ZA ZM ZW',substring(cbc:CompanyID,1,2) ) )"
                    flag="fatal">Party VAT identifiers shall have a prefix in accordance with ISO code ISO 3166-1 alpha-2 by which the country of issue may be identified. Nevertheless, Greece may use the prefix ‘EL’.</assert>
            </rule>
            
            <!-- Document total amounts -->
            <rule context="cac:AnticipatedMonetaryTotal">
                
                <let name="payableAmount" value="xs:decimal(cbc:PayableAmount)"/>
                <let name="lineEtensionAmount" value="xs:decimal(cbc:LineExtensionAmount)"/>
                <let name="prepaidAmount" value="if (cbc:PrepaidAmount) then xs:decimal(cbc:PrepaidAmount) else 0"/>
                <let name="roundingAmount" value="if (cbc:PayableRoundingAmount) then xs:decimal(cbc:PayableRoundingAmount) else 0"/>
                <let name="taxinclusiveAmount" value="xs:decimal(cbc:TaxInclusiveAmount)"/>
                <let name="allowanceTotalAmount" value="if (cbc:AllowanceTotalAmount) then xs:decimal(cbc:AllowanceTotalAmount) else 0"/>
                <let name="chargeTotalAmount" value="if (cbc:ChargeTotalAmount) then xs:decimal(cbc:ChargeTotalAmount) else 0"/>
                <let name="taxexclusiveAmount" value="if(cbc:TaxExclusiveAmount) then xs:decimal(cbc:TaxExclusiveAmount) else ($lineEtensionAmount - $allowanceTotalAmount + $chargeTotalAmount)"/>
          
                              
                <assert id="PEPPOL-T01-R006"
                    test="$payableAmount &gt;=0"    
                    flag="fatal">Expected total amount for payment MUST NOT be negative
                </assert>  
                <assert id="PEPPOL-T01-R007"
                    test="$lineEtensionAmount &gt;=0"    
                    flag="fatal">Expected total sum of line amounts MUST NOT be negative
                </assert>   
                <assert id="PEPPOL-T01-R008"
                    test="$lineEtensionAmount = $sumLineExtensionAmount"  
                    flag="fatal">Expected total sum of line amounts MUST equal the sum of the order line amounts at order line level
                </assert>  
                <assert id="PEPPOL-T01-R009"
                    test="$allowanceTotalAmount = $sumAllowance"  
                    flag="fatal">Expected total sum of allowance at document level MUST be equal to the sum of allowance amounts at document level
                </assert>  
                <assert id="PEPPOL-T01-R010"
                    test="$chargeTotalAmount= $sumCharge"  
                    flag="fatal">Expected total sum of charges at document level MUST be equal to the sum of charge amounts at document level
                </assert>
                
                <assert  id="PEPPOL-T01-R011"
                    test="$taxexclusiveAmount = $lineEtensionAmount - $allowanceTotalAmount + $chargeTotalAmount"
                    flag="fatal">Expected total amount without VAT = Expected total sum of line amounts - Sum of allowances on document level + Sum of charges on document level
                </assert>
                <assert  id="PEPPOL-T01-R016"
                    test="if ($taxinclusiveAmount) then ($payableAmount = $taxinclusiveAmount - $prepaidAmount + $roundingAmount) else $payableAmount"
                    flag="fatal">Amount due for payment = Invoice total amount with VAT - Paid amount + Rounding amount.
                </assert>
                <assert  id="PEPPOL-T01-R017"
                    test="if ($taxinclusiveAmount and $VATamount) then ($taxinclusiveAmount = $taxexclusiveAmount + $VATamount) else $lineEtensionAmount"
                    flag="fatal">Expected total amount with VAT = Expected total amount without VAT + Order total VAT amount.
                </assert>

            </rule>
            
            
            <!-- Allowance/Charge (document level/line level) -->
            <rule context="/ubl-order:Order/cac:AllowanceCharge[cbc:MultiplierFactorNumeric and not(cbc:BaseAmount)] | /ubl-order:Order/cac:OrderLine/cac:LineItem/cac:AllowanceCharge[cbc:MultiplierFactorNumeric and not(cbc:BaseAmount)]">
                <assert id="PEPPOL-T01-R020"
                    test="false()"
                    flag="fatal">Allowance/charge base amount MUST be provided when allowance/charge percentage is provided.</assert>
            </rule>
            
            <rule context="/ubl-order:Order/cac:AllowanceCharge[not(cbc:MultiplierFactorNumeric) and cbc:BaseAmount] | /ubl-order:Order/cac:OrderLine/cac:LineItem/cac:AllowanceCharge[not(cbc:MultiplierFactorNumeric) and cbc:BaseAmount]">
                <assert id="PEPPOL-T01-R021"
                    test="false()"
                    flag="fatal">Allowance/charge percentage MUST be provided when allowance/charge base amount is provided.</assert>
            </rule>  
            
            <rule context="/ubl-order:Order/cac:AllowanceCharge |/ubl-order:Order/cac:OrderLine/cac:LineItem/cac:AllowanceCharge">
                <assert id="PEPPOL-T01-R022"
                    test="not(cbc:MultiplierFactorNumeric and cbc:BaseAmount) or u:slack(if (cbc:Amount) then cbc:Amount else 0, (xs:decimal(cbc:BaseAmount) * xs:decimal(cbc:MultiplierFactorNumeric)) div 100, 0.02)"
                    flag="fatal">Allowance/charge amount must equal base amount * percentage/100 if base amount and percentage exists</assert>
                <assert id="PEPPOL-T01-R023"
                    test="exists(cbc:AllowanceChargeReason) or exists(cbc:AllowanceChargeReasonCode)"
                    flag="fatal">Each document or line level allowance shall have an allowance reason text or an allowance reason code.</assert>
            </rule>
            
            <rule context="cac:TaxCategory | cac:ClassifiedTaxCategory">
            <assert id="PEPPOL-T01-R029"
                test="cbc:Percent or (normalize-space(cbc:ID)='O')"
                flag="fatal">Each Tax Category shall have a VAT category rate, except if the order is not subject to VAT.</assert>            
            <assert id="PEPPOL-T01-R030"
                    test="not(normalize-space(cbc:ID)='S') or (cbc:Percent) &gt; 0" 
                flag="fatal">When VAT category code is "Standard rated" (S) the VAT rate shall be greater than zero.</assert>            
            </rule>
          
            
            <!-- Line level -->       
            <rule context="cac:OrderLine/cac:LineItem"> 
                
            

                <let name="lineExtensionAmount" value="if (cbc:LineExtensionAmount) then xs:decimal(cbc:LineExtensionAmount) else 0"/>
                <let name="quantity" value="if (cbc:Quantity) then xs:decimal(cbc:Quantity) else 1"/>
                <let name="priceAmount" value="if (cac:Price/cbc:PriceAmount) then xs:decimal(cac:Price/cbc:PriceAmount) else 0"/>
                <let name="baseQuantity" value="if (cac:Price/cbc:BaseQuantity and xs:decimal(cac:Price/cbc:BaseQuantity) != 0) then xs:decimal(cac:Price/cbc:BaseQuantity) else 1"/>
                <let name="allowancesTotal" value="if (cac:AllowanceCharge[normalize-space(cbc:ChargeIndicator) = 'false']) then xs:decimal(sum(cac:AllowanceCharge[normalize-space(cbc:ChargeIndicator) = 'false']/cbc:Amount)) else 0"/>
                <let name="chargesTotal" value="if (cac:AllowanceCharge[normalize-space(cbc:ChargeIndicator) = 'true']) then xs:decimal(sum(cac:AllowanceCharge[normalize-space(cbc:ChargeIndicator) = 'true']/cbc:Amount)) else 0"/>
                
                <assert id="PEPPOL-T01-R024"  
                    test="u:slack($lineExtensionAmount, ($quantity * ($priceAmount div $baseQuantity)) + $chargesTotal - $allowancesTotal, 0.02)" 
                    flag="fatal">Order line net amount MUST equal (Ordered quantity * (Item net price/item price base quantity) + Order line charge amount - Order line allowance amount</assert>
                <assert id="PEPPOL-T01-R025"
                    test="not(cac:Price/cbc:BaseQuantity) or xs:decimal(cac:Price/cbc:BaseQuantity) &gt; 0"
                    flag="fatal">Base quantity MUST be a positive number above zero.</assert>
                <assert id="PEPPOL-T01-R001"
                    test="count(key('k_lineId',cbc:ID)) = 1"    
                    flag="fatal">Each order line MUST have a document line identifier that is unique within the order. 
                </assert>  
                <assert id="PEPPOL-T01-R004"
                    test="number(cbc:Quantity) &gt;=0"    
                    flag="fatal">Each order line ordered quantity MUST not be negative
                </assert>                
                <assert id="PEPPOL-T01-R013"
                    test="cbc:Quantity"    
                    flag="warning">Each order line SHOULD have an ordered quantity
                </assert>   
            </rule>

            
            <!-- Item -->
            <rule context="cac:Item">
                <assert id= "PEPPOL-T01-R012"
                    test="(cbc:Name) or (cac:StandardItemIdentification/cbc:ID) or  (cac:SellersItemIdentification/cbc:ID)"
                    flag="fatal">Each order line MUST have an item identifier and/or an item name                 
                </assert>
            </rule>        
            
            <!-- Allowance (price level) -->
            <rule context="cac:Price/cac:AllowanceCharge">
                <assert id="PEPPOL-T01-R019"
                    test="not(cbc:BaseAmount) or xs:decimal(../cbc:PriceAmount) = xs:decimal(cbc:BaseAmount) - xs:decimal(cbc:Amount)"
                    flag="fatal">Item net price MUST equal (Gross price - Allowance amount) when gross price is provided.</assert>
            </rule>
            
            <!-- Price -->
            <rule context="cac:Price">
                <assert id="PEPPOL-T01-R005"
                    test="number(cbc:PriceAmount) &gt;=0"    
                    flag="fatal">Each order line item net price MUST not be negative
                </assert>   
                <assert  id="PEPPOL-T01-R027"
                    test="(cac:Price/cac:AllowanceCharge/cbc:BaseAmount) &gt;= 0 or not(exists(cac:Price/cac:AllowanceCharge/cbc:BaseAmount))"
                    flag="fatal">The Item gross price shall NOT be negative.</assert>
            </rule>
   
        </pattern>

        
  
    
</schema>