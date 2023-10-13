use pythnet_sdk::accumulators::merkle::MerklePath;
use pythnet_sdk::hashers::keccak256_160::Keccak160;
use pythnet_sdk::wire::array;
use serde::Deserialize;
use serde::Serialize;

use {
    anyhow::Result,
    axum::{
        extract::State,
        Json,
    },
    base64::{
        engine::general_purpose::STANDARD as base64_standard_engine,
        Engine as _,
    },
    serde_qs::axum::QsQuery,
    utoipa::{
        IntoParams,
        ToSchema,
    },
};
use crate::api::RestError;

// FIXME docs
/// Get a VAA for a price feed with a specific timestamp
///
/// Given a price feed id and timestamp, retrieve the Pyth price update closest to that timestamp.
#[utoipa::path(
get,
path = "/api/get_random_value",
responses(
(status = 200, description = "Price update retrieved successfully", body = GetRandomValueResponse),
(status = 404, description = "Price update not found", body = String)
),
params(
GetRandomValueQueryParams
)
)]
pub async fn get_random_value(
    State(state): State<crate::api::ApiState>,
    QsQuery(params): QsQuery<GetRandomValueQueryParams>,
) -> Result<Json<GetRandomValueResponse>, RestError> {
    // TODO: check on-chain sequence number here
    let value = &state.state.reveal_ith(params.sequence.try_into().map_err(|_| RestError::TestError)?).map_err(|_| RestError::TestError)?;

    Ok(Json(GetRandomValueResponse { value: (*value).clone() } ))
}

#[derive(Debug, serde::Deserialize, IntoParams)]
#[into_params(parameter_in=Query)]
pub struct GetRandomValueQueryParams {
    sequence: u64,
}

#[derive(Debug, serde::Serialize, ToSchema)]
pub struct GetRandomValueResponse {
    #[serde(with = "array")]
    value:      [u8; 32],
}