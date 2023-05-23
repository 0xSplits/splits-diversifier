# splits-diversifier

[Docs](https://dev.docs.0xsplits.xyz/templates/diversifier)

## What

Diversifier is a 0xSplits template that diversifies onchain revenue.

## Why

Many onchain entities (e.g. creators, collectives, DAOs, businesses) generate onchain revenues in tokens that don't match the denominations of their expenses (e.g. salaries, taxes) resulting in [asset-liability currency mismatch](https://en.wikipedia.org/wiki/Asset%E2%80%93liability_mismatch#Currency_Mismatch).
More generally, diversifying onchain revenue is an easy, efficient, & trustless way to build & manage onchain wallets & treasuries for high performance across a variety of crypto-market conditions.

## How

Generic diversifier example:

[![](https://mermaid.ink/img/pako:eNp1kDGLwzAMhf9K0FwP124eOmU9KJeDLl5ErDQCxzaK3FJK_3t9SZccVJP03ieB3gP65AksGGNcVNZAtmn5SjLzwCQuLsYQ0q0fUdTFptYJ5_l3lFQu4xlDIG2MOTZdDlyBFVmGRf6hnjNT1K__TnfDnEn2H_TDW39T22P7jXnYmnUTdjCRTMi-Pvf4gx3oSBM5sLX1NGAJ6sDFZ0WxaOrusQerUmgHJXtUahkvghPYAcNcVfKsSb7XwJbcni97bWjr?type=png)](https://mermaid.live/edit#pako:eNp1kDGLwzAMhf9K0FwP124eOmU9KJeDLl5ErDQCxzaK3FJK_3t9SZccVJP03ieB3gP65AksGGNcVNZAtmn5SjLzwCQuLsYQ0q0fUdTFptYJ5_l3lFQu4xlDIG2MOTZdDlyBFVmGRf6hnjNT1K__TnfDnEn2H_TDW39T22P7jXnYmnUTdjCRTMi-Pvf4gx3oSBM5sLX1NGAJ6sDFZ0WxaOrusQerUmgHJXtUahkvghPYAcNcVfKsSb7XwJbcni97bWjr)

Tax withholder example:

[![](https://mermaid.ink/img/pako:eNpdkDFrAzEMhf-KEZQsOehQMnjo0qyFkkvJUHcQZ93Z4LONLZOWJP-9jq8pbTVZ73sSzzrBEDSBhK7rlGfLjqTY44c4WDYmOE1J-cZGF46DwcTKi1o7Gmy05L_bkt8UvPbbJ9EfMcY6Be8LSVzJj3uV_2y3fsrNuXhfMOe9SaFM5oDOEYuuexR9dJZvltY0-by5vzv_i_GLPlRa8i1d067ZYQ0zpRmtrp8-XbECNjSTAlmfmkYsjhUof6lWLBz6Tz-A5FRoDSVqZNpanBLOIEd0uaqkLYf0vByy3fPyBYJ3cWI?type=png)](https://mermaid.live/edit#pako:eNpdkDFrAzEMhf-KEZQsOehQMnjo0qyFkkvJUHcQZ93Z4LONLZOWJP-9jq8pbTVZ73sSzzrBEDSBhK7rlGfLjqTY44c4WDYmOE1J-cZGF46DwcTKi1o7Gmy05L_bkt8UvPbbJ9EfMcY6Be8LSVzJj3uV_2y3fsrNuXhfMOe9SaFM5oDOEYuuexR9dJZvltY0-by5vzv_i_GLPlRa8i1d067ZYQ0zpRmtrp8-XbECNjSTAlmfmkYsjhUof6lWLBz6Tz-A5FRoDSVqZNpanBLOIEd0uaqkLYf0vByy3fPyBYJ3cWI)

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
