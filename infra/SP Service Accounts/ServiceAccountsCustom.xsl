<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="/">
        <html>
            <head>
                <link rel="stylesheet" href="ServiceAccountsCustom.css" />
                <title>SharePoint Service Accounts</title>
            </head>
            <body>
                <h2>SharePoint Service Accounts</h2>
                <table border="1">
                    <tr>
                        <th>Display Name</th>
                        <th>Username</th>
                        <th>Password</th>
                        <th>Description</th>
                    </tr>
                    <xsl:for-each select="ServiceAccounts/User">
                        <tr>
                            <td>
                                <xsl:value-of select="FirstName"/>
                                <xsl:text> </xsl:text>
                                <xsl:value-of select="LastName"/>
                            </td>
                            <td>
                                <xsl:value-of select="UserName"/>
                            </td>
                            <td>
                                <xsl:value-of select="Password"/>
                            </td>
                            <td>
                                <xsl:value-of select="Description"/>
                            </td>
                        </tr>
                    </xsl:for-each>
                </table>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet> 