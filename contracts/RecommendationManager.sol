// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RecommendationManager {
    struct Recommendation {
        address recommender;
        address recommended;
        uint256 timestamp;
        bool isActive;
    }

    mapping(address => Recommendation) public recommendations;

    event RecommendationMade(address recommender, address recommended);
    event RecommendationFinalized(address recommended, bool successful);

    function recommend(address recommender, address recommended) external {
        require(recommendations[recommended].recommender == address(0), "Already recommended");
        recommendations[recommended] = Recommendation({
            recommender: recommender,
            recommended: recommended,
            timestamp: block.timestamp,
            isActive: true
        });
        emit RecommendationMade(recommender, recommended);
    }

    function finalizeRecommendation(address recommended, bool successful) external {
        Recommendation storage recommendation = recommendations[recommended];
        require(recommendation.isActive, "Recommendation is not active");

        recommendation.isActive = false;
        emit RecommendationFinalized(recommended, successful);
    }

    function getRecommendation(address recommended) external view returns (address recommender, bool isActive) {
        Recommendation storage recommendation = recommendations[recommended];
        return (recommendation.recommender, recommendation.isActive);
    }
}
