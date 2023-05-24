# Sourced from https://support.microsoft.com/en-us/topic/resolving-view-state-message-authentication-code-mac-errors-6c0e9fd3-f8a8-c953-8fbe-ce840446a9f3#bkmk_appendixa
# with minor adjustments

function ConvertTo-Hex {
  [CmdLetBinding()]
  [OutputType('')]
  param(
    [System.Byte[]] $Bytes
  )

  process {
    $builder = New-Object System.Text.StringBuilder

    foreach ($b in $Bytes) {
      $builder = $builder.AppendFormat(
        [System.Globalization.CultureInfo]::InvariantCulture,
        '{0:X2}',
        $b
      )
    }

    $builder.ToString()
  }
}

function Initialize-MachineKey {
  [CmdletBinding()]
  [OutputType('')]
  param (
    [ValidateSet('AES', 'DES', '3DES')]
    [System.String]
    $DecryptionAlgorithm = 'AES',

    [ValidateSet('CONFIG', 'JSON')]
    [System.String]
    $OutputType = 'CONFIG',

    [ValidateSet('MD5', 'SHA1', 'HMACSHA256', 'HMACSHA384', 'HMACSHA512')]
    [System.String]
    $ValidationAlgorithm = 'HMACSHA256'
  )

  process {
    switch ($DecryptionAlgorithm) {
      'AES' { $decryptionObject = New-Object System.Security.Cryptography.AesCryptoServiceProvider }
      'DES' { $decryptionObject = New-Object System.Security.Cryptography.DESCryptoServiceProvider }
      '3DES' { $decryptionObject = New-Object System.Security.Cryptography.TripleDESCryptoServiceProvider }
    }

    $decryptionObject.GenerateKey()
    $decryptionKey = ConvertTo-Hex($decryptionObject.Key)
    $decryptionObject.Dispose()

    switch ($ValidationAlgorithm) {
      'MD5' { $validationObject = New-Object System.Security.Cryptography.HMACMD5 }
      'SHA1' { $validationObject = New-Object System.Security.Cryptography.HMACSHA1 }
      'HMACSHA256' { $validationObject = New-Object System.Security.Cryptography.HMACSHA256 }
      'HMACSHA385' { $validationObject = New-Object System.Security.Cryptography.HMACSHA384 }
      'HMACSHA512' { $validationObject = New-Object System.Security.Cryptography.HMACSHA512 }
    }

    $validationKey = ConvertTo-Hex($validationObject.Key)
    $validationObject.Dispose()

    if ($OutputType -eq 'CONFIG') {
      $result = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture,
        "<machineKey decryption=`"{0}`" decryptionKey=`"{1}`" validation=`"{2}`" validationKey=`"{3}`" />",
        $DecryptionAlgorithm.ToUpperInvariant(), $decryptionKey,
        $ValidationAlgorithm.ToUpperInvariant(), $validationKey
      )
    } else {
      $result = @{
        'DecryptionKey'    = $decryptionKey
        'DecryptionMethod' = $DecryptionAlgorithm.ToUpperInvariant()
        'ValidationKey'    = $validationKey
        'ValidationMethod' = $ValidationAlgorithm.ToUpperInvariant()
      } | ConvertTo-Json -Compress
    }

    $result
  }
}
