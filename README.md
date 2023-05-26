# splits-diversifier

[Docs](https://docs.0xsplits.xyz/templates/diversifier)

## What

Diversifier is a 0xSplits template that diversifies onchain revenue.

![](https://docs.0xsplits.xyz/_next/image?url=%2F_next%2Fstatic%2Fmedia%2Fdiversifier_diagram.9dfbf3b2.png&w=3840&q=75)

## Why

Many onchain entities (e.g. creators, collectives, DAOs, businesses) generate onchain revenues in tokens that don't match the denominations of their expenses (e.g. salaries, taxes) resulting in [asset-liability currency mismatch](https://en.wikipedia.org/wiki/Asset%E2%80%93liability_mismatch#Currency_Mismatch).
More generally, diversifying onchain revenue is an easy, efficient, & trustless way to build & manage onchain wallets & treasuries for high performance across a variety of crypto-market conditions.

## How

[![Diversifier flow chart](https://mermaid.ink/svg/pako:eNqNk8tuwjAQRX_FcoWyIRIlvJRFJV7ZVapK1W6yGZIBRnLsyJlAEeLfmxhoG0RRN37ce-ZalscHmZgUZSh93481EysMxYy2aAtaEdpYOyPWrdYh1kKQJg6FWwrh8QYz9ELhLaFAr_1bfQdLsFRYeN-4M1dGcwQZqX1dV0PqUuh8RRqnRhlb2w-DybA76jQAxk--C-SWMrD7HyYKol40uMVMjE3R3k0rMDE6beQN5vPhZHibuk7s9IajfpOFhGkLTEb_A2a0TI3Tx_1JL5rehK7zekEwmo69E3msp2o4tlr1e66U2SUbsHxyX6Ao3jbWlOvNByiFLHz_SSxyRVzTNeI2Tn7FhHJCzY_XzmIHeY62-4cenPUz1QzrNsygaVaVsi0ztBlQWrWra6lYulaLZVgtU1xBqTiW1RUrFEo2i71OZMi2xLYs8xQYZwRrC9lFxJTY2OfTD3Af4fgF-uvqYg)](https://mermaid.live/edit#pako:eNqNk0lrwzAQhf-KUAm-xJDG2fChkM23QmlKe_FlYo-TAVky8jhpCPnvtZVuDmnoRct73zwhNDrKxKQoQ-n7fqyZWGEoFrRDW1JGaGPtjFh3OsdYC0GaOBRuKYTHW8zRC4W3hhK97m_1FSzBWmHpfePOzIzmCHJSh6augdRXofMVaZwbZWxj341m4_6k1wIY3_kmUFjKwR5-mCiIBtHoGjMzNkV7M63ExOi0lTdaLsez8XXqMrE3GE-GbRYSph0wGf0PmNEytU6fDmeDaH4VuswbBMFkPvXO5KmZ6uHU6TTvmSmzT7Zg-ew-QVm-bK2pNts3UApZ-P6DWBWKuKEbxG2c_IwJFYSa7y-d1R6KAm3_Dz341D-pdli_ZQZts66UXZmjzYHSul1dS8XStVosw3qZYgaV4ljWV6xRqNisDjqRIdsKu7IqUmBcEGws5DLMQJW1iimxsY_nL-B-wukD5E3qrQ)

### How does it diversify onchain revenue?

A Split with Swappers underneath (all controlled/owned by a PassThroughWallet sitting on top).

### How is it governed?

A Diversifier's owner, if set, has _FULL CONTROL_ of the deployment.
It may, at any time for any reason, change any mutable storage in any of the underlying components, as well as execute arbitrary calls on behalf of the Diversifier.
In situations where flows ultimately belong to or benefit more than a single person & immutability is a nonstarter, we strongly recommend using multisigs or DAOs for governance.
To the extent your oracle has a separate owner as well, similar logic applies.

## Lint

`forge fmt`

## Setup & test

`forge i` - install dependencies

`forge b` - compile the contracts

`forge t` - compile & test the contracts

`forge t -vvv` - produces a trace of any failing tests

## Natspec

`forge doc --serve --port 4000` - serves natspec docs at http://localhost:4000/
