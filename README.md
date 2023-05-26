# splits-diversifier

[Docs](https://docs.0xsplits.xyz/templates/diversifier)

## What

Diversifier is a 0xSplits template that diversifies onchain revenue.

![](https://docs.0xsplits.xyz/_next/image?url=%2F_next%2Fstatic%2Fmedia%2Fdiversifier_diagram.9dfbf3b2.png&w=3840&q=75)

## Why

Many onchain entities (e.g. creators, collectives, DAOs, businesses) generate onchain revenues in tokens that don't match the denominations of their expenses (e.g. salaries, taxes) resulting in [asset-liability currency mismatch](https://en.wikipedia.org/wiki/Asset%E2%80%93liability_mismatch#Currency_Mismatch).
More generally, diversifying onchain revenue is an easy, efficient, & trustless way to build & manage onchain wallets & treasuries for high performance across a variety of crypto-market conditions.

## How

[![Diversifier flow chart](https://mermaid.ink/img/pako:eNqNk0lrwzAQhf-KUAm-xJDG2fChkM23QmlKe_FlYo-TAVky8jhpCPnvtZVuDmnoRct73zwhNDrKxKQoQ-n7fqyZWGEoFrRDW1JGaGPtjFh3OsdYC0GaOBRuKYTHW8zRC4W3hhK97m_1FSzBWmHpfePOzIzmCHJSh6augdRXofMVaZwbZWxj341m4_6k1wIY3_kmUFjKwR5-mCiIBtHoGjMzNkV7M63ExOi0lTdaLsez8XXqMrE3GE-GbRYSph0wGf0PmNEytU6fDmeDaH4VuswbBMFkPvXO5KmZ6uHU6TTvmSmzT7Zg-ew-QVm-bK2pNts3UApZ-P6DWBWKuKEbxG2c_IwJFYSa7y-d1R6KAm3_Dz341D-pdli_ZQZts66UXZmjzYHSul1dS8XStVosw3qZYgaV4ljWV6xRqNisDjqRIdsKu7IqUmBcEGws5DLMQJW1iimxsY_nL-B-wukD5E3qrQ?type=png)](https://mermaid.live/edit#pako:eNqNk0lrwzAQhf-KUAm-xJDG2fChkM23QmlKe_FlYo-TAVky8jhpCPnvtZVuDmnoRct73zwhNDrKxKQoQ-n7fqyZWGEoFrRDW1JGaGPtjFh3OsdYC0GaOBRuKYTHW8zRC4W3hhK97m_1FSzBWmHpfePOzIzmCHJSh6augdRXofMVaZwbZWxj341m4_6k1wIY3_kmUFjKwR5-mCiIBtHoGjMzNkV7M63ExOi0lTdaLsez8XXqMrE3GE-GbRYSph0wGf0PmNEytU6fDmeDaH4VuswbBMFkPvXO5KmZ6uHU6TTvmSmzT7Zg-ew-QVm-bK2pNts3UApZ-P6DWBWKuKEbxG2c_IwJFYSa7y-d1R6KAm3_Dz341D-pdli_ZQZts66UXZmjzYHSul1dS8XStVosw3qZYgaV4ljWV6xRqNisDjqRIdsKu7IqUmBcEGws5DLMQJW1iimxsY_nL-B-wukD5E3qrQ)

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
