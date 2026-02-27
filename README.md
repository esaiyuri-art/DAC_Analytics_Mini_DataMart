Overview

This project is an end-to-end SQL Server mini data mart designed to model club membership, amenity usage, entitlements, and profitability. It demonstrates dimensional modeling concepts including transactional and aggregate fact tables, normalized dimensions, and a bridge table to support many-to-many relationships between membership tiers and amenities.

The solution includes:

Transactional Fact Table capturing individual amenity usage events
Monthly Aggregate Fact Table summarizing usage and operating cost at the amenity/month grain
Dimensional Tables for amenities, memberships, members, and dates
Bridge Table Design to model membership entitlements and included amenities
Cost & Pricing Model enabling margin and profitability analysis
Data Integrity Constraints enforcing grain, valid date alignment, and non-negative measures
BI-Ready Views structured for downstream reporting in Power BI or Qlik
This project emphasizes:
Clear grain definition for each fact table
Enforced uniqueness and referential integrity
Maintainable schema design with documented design rationale
Separation of transactional detail from performance-optimized aggregates
Extensibility for future enhancements (e.g., SCD2 pricing, surrogate date keys, advanced cost allocation)

The goal of this repository is to showcase dimensional modeling, SQL development standards, and the ability to design a structured analytical layer from the ground up.

Disclaimer: All data within this repository is mock data generated for demonstration and portfolio purposes only. It does not represent any real organization, customer, or financial information.
